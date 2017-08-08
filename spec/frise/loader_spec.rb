require 'frise/loader'

include Frise

RSpec.describe Loader do
  it 'should load a config, applying default values in a load path' do
    loader = Loader.new(
      defaults_load_paths: [fixture_path('_defaults')]
    )

    conf = loader.load(fixture_path('loader_test_1.yml'), false)
    expect(conf).to eq(
      'str' => 'str',
      'int' => -1,
      'bool' => true,
      'arr' => %w[def_elem elem0 elem1],
      'obj' => { 'key1' => 'def_value1', 'key2' => 'value2', 'key3' => 'def_value3' },
      'record' => { 'field1' => 'f1', 'field2' => true }
    )
  end

  it 'should load a config, validating it with a schema in a load path' do
    validators = Object.new
    def validators.short_string(_, str)
      str.is_a?(String) && str.length < 5 || (raise "expected a short string, found #{str.inspect}")
    end

    loader = Loader.new(
      schema_load_paths: [fixture_path('_schemas')],
      validators: validators
    )

    conf = loader.load(fixture_path('loader_test_1.yml'), false)
    expect(conf).to eq(nil) # At int: missing required value

    loader = Loader.new(
      schema_load_paths: [fixture_path('_schemas')],
      defaults_load_paths: [fixture_path('_defaults')],
      validators: validators
    )

    conf = loader.load(fixture_path('loader_test_1.yml'), false)
    expect(conf).to eq(
      'str' => 'str',
      'int' => -1,
      'bool' => true,
      'arr' => %w[def_elem elem0 elem1],
      'obj' => { 'key1' => 'def_value1', 'key2' => 'value2', 'key3' => 'def_value3' },
      'record' => { 'field1' => 'f1', 'field2' => true }
    )
  end

  it 'should print validation errors and terminate if exit_on_fail is true' do
    validators = Object.new
    def validators.short_string(_, str)
      str.is_a?(String) && str.length < 5 || (raise "expected a short string, found #{str.inspect}")
    end

    loader = Loader.new(
      schema_load_paths: [fixture_path('_schemas')],
      validators: validators
    )

    expect { loader.load(fixture_path('loader_test_1.yml'), true) }.to output(
      "1 config error(s) found:\n" \
      " - At int: missing required value\n"
    ).to_stdout.and raise_error(SystemExit)
  end

  it 'should use an extra symbol table when provided' do
    loader = Loader.new(
      schema_load_paths: [fixture_path('_schemas')],
      defaults_load_paths: [fixture_path('_defaults')]
    )

    conf = loader.load(fixture_path('loader_test_2.yml'), false, '_id' => 'myobj')
    expect(conf).to eq(
      'id' => 'myobj',
      'name' => 'My Object',
      'description' => 'Description of My Object'
    )
  end
end
