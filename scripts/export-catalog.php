<?php
/**
 * Export the shipped components as a static catalog.
 *
 * Runs inside WordPress, because the point of it is to run the components
 * themselves: `render.php` is PHP against WordPress helpers, and anything that
 * imitates its output in another language is a second implementation that goes
 * stale at the next release.
 *
 * Called by scripts/export.sh, which copies this file, the examples and the
 * plugin into the wp-env CLI container and collects the output. Arguments:
 *
 *   wp eval-file export-catalog.php <examples-dir> <out-dir>
 *
 * Writes into <out-dir>:
 *
 *   preview/<type>.html        rendered component, exactly as the frontend prints it
 *   src/<type>/…               the component's own files, for the code panes
 *   catalog.json               everything the site needs, derived from the definitions
 *
 * Missing example data is a hard error, not a warning: a component without an
 * example would otherwise ship as an empty preview that looks like a broken
 * component.
 */

if ( ! defined( 'ABSPATH' ) ) {
	fwrite( STDERR, "Run this through wp eval-file.\n" );
	exit( 1 );
}

$examples_dir = isset( $args[0] ) ? rtrim( (string) $args[0], '/' ) : '';
$out_dir      = isset( $args[1] ) ? rtrim( (string) $args[1], '/' ) : '';

if ( '' === $examples_dir || '' === $out_dir ) {
	fwrite( STDERR, "Usage: wp eval-file export-catalog.php <examples-dir> <out-dir>\n" );
	exit( 1 );
}

if ( ! class_exists( 'Sdcpb_Frontend' ) || ! class_exists( 'Sdcpb_View' ) ) {
	fwrite( STDERR, "The page builder is not loaded — activate it in this environment.\n" );
	exit( 1 );
}

/*
 * The components are read from the plugin that is actually loaded, not from a
 * path given on the command line. Otherwise the markup could come from one
 * checkout and the definitions from another, and the catalog would describe a
 * component that nobody ships.
 */
$reflection = new ReflectionClass( 'Sdcpb_Frontend' );
$plugin_dir = rtrim( dirname( dirname( $reflection->getFileName() ) ), '/' );
$schema_dir = $plugin_dir . '/schemas';

if ( ! is_dir( $schema_dir ) ) {
	fwrite( STDERR, "No schemas directory at {$schema_dir}\n" );
	exit( 1 );
}

$failures = array();
$entries  = array();

/**
 * Depth of a field tree: 1 for flat fields, 2 for a repeater, 3 for nested ones.
 *
 * @param array $fields Field definitions.
 * @return int
 */
function sdcpb_export_depth( array $fields ) {
	$depth = 0;

	foreach ( $fields as $field ) {
		$sub = array();

		foreach ( array( 'sub_fields', 'fields' ) as $key ) {
			if ( ! empty( $field[ $key ] ) && is_array( $field[ $key ] ) ) {
				$sub = array_merge( $sub, $field[ $key ] );
			}
		}

		$depth = max( $depth, 1 + ( $sub ? sdcpb_export_depth( $sub ) : 0 ) );
	}

	return $depth;
}

/**
 * Field rows for the table on the detail page: name, label, type, required.
 *
 * @param array  $fields Field definitions.
 * @param int    $level  Nesting level, 1-based.
 * @return array[]
 */
function sdcpb_export_field_rows( array $fields, $level = 1 ) {
	$rows = array();

	foreach ( $fields as $field ) {
		$rows[] = array(
			'name'        => (string) ( $field['name'] ?? '' ),
			'label'       => (string) ( $field['label'] ?? '' ),
			'type'        => (string) ( $field['type'] ?? '' ),
			'required'    => ! empty( $field['required'] ),
			'level'       => $level,
			'instructions' => (string) ( $field['instructions'] ?? '' ),
		);

		foreach ( array( 'sub_fields', 'fields' ) as $key ) {
			if ( ! empty( $field[ $key ] ) && is_array( $field[ $key ] ) ) {
				$rows = array_merge( $rows, sdcpb_export_field_rows( $field[ $key ], $level + 1 ) );
			}
		}
	}

	return $rows;
}

$dirs = glob( $schema_dir . '/*/definition.json' );
sort( $dirs );

foreach ( $dirs as $file ) {
	$type       = basename( dirname( $file ) );
	$definition = json_decode( (string) file_get_contents( $file ), true );

	if ( ! is_array( $definition ) ) {
		$failures[] = "{$type}: definition.json is not valid JSON";
		continue;
	}

	$example_file = $examples_dir . '/' . $type . '.json';

	if ( ! is_readable( $example_file ) ) {
		$failures[] = "{$type}: no example data at examples/{$type}.json";
		continue;
	}

	$example = json_decode( (string) file_get_contents( $example_file ), true );

	if ( ! is_array( $example ) || ! isset( $example['data'] ) || ! is_array( $example['data'] ) ) {
		$failures[] = "{$type}: examples/{$type}.json needs an object with a \"data\" key";
		continue;
	}

	$html = Sdcpb_Frontend::render_instance( $type, $example['data'], 0 );

	if ( '' === trim( (string) $html ) ) {
		$failures[] = "{$type}: rendered an empty string";
		continue;
	}

	$fields     = isset( $definition['fields'] ) && is_array( $definition['fields'] ) ? $definition['fields'] : array();
	$template   = Sdcpb_Schema::template( $type );
	$stylesheet = Sdcpb_View::style( $type );

	// Component sources, so the detail page can show them without a second copy
	// in this repository.
	$src_dir = $out_dir . '/src/' . $type;
	wp_mkdir_p( $src_dir );
	copy( $file, $src_dir . '/definition.json' );

	$files = array( 'definition.json' );
	foreach ( array( 'render.php' => $template, 'component.css' => $stylesheet ) as $name => $path ) {
		if ( '' !== (string) $path && is_readable( $path ) ) {
			copy( $path, $src_dir . '/' . $name );
			$files[] = $name;
		}
	}

	wp_mkdir_p( $out_dir . '/preview' );
	file_put_contents( $out_dir . '/preview/' . $type . '.html', (string) $html );

	$entries[] = array(
		'type'         => $type,
		'title'        => (string) ( $definition['title'] ?? $type ),
		'description'  => (string) ( $definition['sdcpb_description'] ?? '' ),
		'icon'         => (string) ( $definition['sdcpb_icon'] ?? '' ),
		'version'      => (int) ( $definition['sdcpb_version'] ?? 0 ),
		'note'         => (string) ( $example['note'] ?? '' ),
		'capabilities' => array_values( (array) ( $example['capabilities'] ?? array() ) ),
		'files'        => $files,
		'depth'        => sdcpb_export_depth( $fields ),
		'fields'       => sdcpb_export_field_rows( $fields ),
		'size'         => strlen( (string) $html ),
	);

	echo "{$type}: " . strlen( (string) $html ) . " bytes\n";
}

if ( $failures ) {
	fwrite( STDERR, "\nKein Katalog geschrieben:\n  " . implode( "\n  ", $failures ) . "\n" );
	exit( 1 );
}

$catalog = array(
	'generated'  => gmdate( 'c' ),
	'plugin'     => array(
		'name'    => 'PhoenixSEO Page Builder',
		'version' => defined( 'SDCPB_VERSION' ) ? SDCPB_VERSION : '',
		'repo'    => 'https://github.com/phoenixseo/sdc-page-builder',
		'license' => 'GPL-2.0-or-later',
	),
	'components' => $entries,
);

wp_mkdir_p( $out_dir );
file_put_contents(
	$out_dir . '/catalog.json',
	(string) wp_json_encode( $catalog, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE ) . "\n"
);

echo "\n" . count( $entries ) . " components -> {$out_dir}/catalog.json\n";
