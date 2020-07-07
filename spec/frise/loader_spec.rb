# frozen_string_literal: true

require 'frise/loader'

include Frise

validators = Object.new
def validators.short_string(_, str)
  str.is_a?(String) && str.length < 5 || (raise "expected a short string, found #{str.inspect}")
end

RSpec.describe Loader do
  it 'should load a config, merging the files declared with $include' do
    loader = Loader.new(exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test1_include.yml'))
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
    loader = Loader.new(validators: validators, exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test1_schema.yml'))
    expect(conf).to eq(nil) # At int: missing required value

    conf = loader.load(fixture_path('loader_test1_all.yml'))
    expect(conf).to eq(
      'str' => 'str',
      'int' => -1,
      'bool' => true,
      'arr' => %w[def_elem elem0 elem1],
      'obj' => { 'key1' => 'def_value1', 'key2' => 'value2', 'key3' => 'def_value3' },
      'record' => { 'field1' => 'f1', 'field2' => true }
    )
  end

  it 'should allow providing actions to be run just before loading defaults and schemas' do
    on_load = ->(conf) { conf.map { |k, v| ["prefix_#{k}", v] }.to_h }

    loader = Loader.new(pre_loaders: [on_load], exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test1_none.yml'))
    expect(conf).to eq(
      'prefix_str' => 'str',
      'prefix_bool' => true,
      'prefix_arr' => %w[elem0 elem1],
      'prefix_obj' => { 'key2' => 'value2' },
      'prefix_record' => { 'field1' => 'f1', 'field2' => true }
    )
  end

  it 'should print validation errors and terminate if exit_on_fail is true' do
    loader = Loader.new(validators: validators, exit_on_fail: true)

    expect { loader.load(fixture_path('loader_test1_schema.yml')) }.to output(
      "1 config error(s) found:\n" \
      " - At int: missing required value\n"
    ).to_stdout.and raise_error(SystemExit)
  end

  it 'should use an extra symbol table when provided' do
    loader = Loader.new(exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test2_all.yml'), '_id' => 'myobj', '_extra' => { 'a' => 42 })
    expect(conf).to eq(
      'id' => 'myobj',
      'name' => 'My Object',
      'description' => 'Description of My Object (42)',
      'other' => 'plain'
    )
  end

  it 'should allow using a different key or no key for inclusions/schemas/deletes' do
    loader = Loader.new(include_sym: '__custom_inc',
                        schema_sym: '__custom_sch',
                        delete_sym: '__custom_del',
                        exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test2_all_alt.yml'), '_id' => 'myobj')
    expect(conf).to eq(
      'id' => 'myobj',
      'name' => 'My Object',
      'description' => 'Description of My Object'
    )

    loader = Loader.new(include_sym: nil, schema_sym: nil, exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test1_all.yml'))
    expect(conf).to eq(
      '$schema' => [fixture_path('_schemas/loader_test1.yml')],
      '$include' => [fixture_path('_defaults/loader_test1.yml')],
      'str' => 'str',
      'bool' => true,
      'arr' => %w[elem0 elem1],
      'obj' => { 'key2' => 'value2' },
      'record' => { 'field1' => 'f1', 'field2' => true }
    )
  end

  it 'should process inclusions and schemas recursively' do
    loader = Loader.new(exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test3.yml'))
    expect(conf).to eq(
      'id' => 'myobj',
      'name' => 'My Object',
      'description' => 'Description of My Object',
      'age' => 20
    )
  end

  it 'should process inclusions and schemas deep in the config, providing a _this variable in defaults' do
    loader = Loader.new(exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test4.yml'))
    expect(conf).to eq(
      'key1' => {
        'value1_1' => 1,
        'value1_2' => 'abc',
        'key2' => { 'value2_1' => 2 }
      }
    )
  end

  it 'should process multiple inclusions and schemas in the same position' do
    loader = Loader.new(exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test5.yml'))
    expect(conf).to eq(
      'key1' => 'abc',
      'key2' => 42
    )
  end

  it 'should process parent inclusions before child inclusions' do
    loader = Loader.new(exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test8.yml'))
    expect(conf).to eq(
      'str1' => 'abc',
      'str2' => 'def',
      'obj' => { 'str12' => 'abcdef' }
    )
  end

  it 'should process inclusions and schemas generated with templating' do
    loader = Loader.new(exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test2_templated.yml'))
    expect(conf).to eq('name' => 'My Object')

    conf = loader.load(fixture_path('loader_test2_templated.yml'),
                       '_id' => 'myobj',
                       '_with_defaults' => true)
    expect(conf).to eq(
      'id' => 'myobj',
      'name' => 'My Object',
      'description' => 'Description of My Object',
      'other' => 'plain'
    )

    conf = loader.load(fixture_path('loader_test2_templated.yml'), '_with_schema' => true)
    expect(conf).to eq(nil) # missing values in defaults

    conf = loader.load(fixture_path('loader_test2_templated.yml'),
                       '_id' => 'myobj',
                       '_with_defaults' => true,
                       '_with_schema' => true)
    expect(conf).to eq(
      'id' => 'myobj',
      'name' => 'My Object',
      'description' => 'Description of My Object',
      'other' => 'plain'
    )
  end

  it 'should allow inclusions with custom variables' do
    loader = Loader.new(exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test6.yml'))
    expect(conf).to eq(
      'rootkey' => true,
      'obj1' => { 'key1' => 42, 'key2' => 'abc' },
      'obj2' => { 'concat' => '42-true' }
    )
  end

  it 'should allow including the content of a file directly as text' do
    loader = Loader.new(exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test9.yml'))
    expect(conf).to eq('str1' => 'Novo Reino',
                       'str2' => <<~STR
                         As armas e os barões assinalados,
                         Que da ocidental praia Lusitana,
                         Por mares nunca de antes navegados,
                         Passaram ainda além da Taprobana,
                         Em perigos e guerras esforçados,
                         Mais do que prometia a força humana,
                         E entre gente remota edificaram
                         Novo Reino, que tanto sublimaram
                       STR
                      )
  end

  it 'should disallow config objects with $content_include and other keys' do
    loader = Loader.new(exit_on_fail: false)

    expect { loader.load(fixture_path('loader_test10.yml')) }.to raise_error(
      'At str2: a $content_include must not have any sibling key'
    )
  end

  it 'should raise an error when an include or schema value is invalid' do
    loader = Loader.new(exit_on_fail: false)
    expect { loader.load(fixture_path('loader_test7_obj_include.yml')) }.to raise_error(
      'At <root>: illegal value for $include: {}'
    )
    expect { loader.load(fixture_path('loader_test7_num_arr_include.yml')) }.to raise_error(
      'At <root>: illegal value for a $include element: 0'
    )
    expect { loader.load(fixture_path('loader_test7_num_schema.yml')) }.to raise_error(
      'At <root>: illegal value for $schema: 0'
    )
    expect { loader.load(fixture_path('loader_test7_obj_arr_schema.yml')) }.to raise_error(
      'At <root>: illegal value for a $schema element: {}'
    )
  end

  it 'should return nil if the file does not exist' do
    loader = Loader.new(exit_on_fail: false)
    expect(loader.load('non_existing_path.yml')).to eq(nil)
  end

  it 'should allow referencing variables included in other files higher up in the configuration tree' do
    loader = Loader.new(exit_on_fail: false)
    conf = loader.load(fixture_path('loader_test11.yml'))

    expect(conf).to eq(
      'foo' => {
        'bar' => {
          'other' => 'Something',
          'baz' => 'Hello World',
          'var1' => {
            'var2' => 'Hello World'
          }
        }
      }
    )
  end

  it 'should validate schemas included deeper in the config file hierarchy' do
    loader = Loader.new(exit_on_fail: true)
    expect { loader.load(fixture_path('loader_test12.yml')) }.to output(
      "1 config error(s) found:\n" \
      " - At variable1.value2: missing required value\n"
    ).to_stdout.and raise_error(SystemExit)
  end

  it 'should delete sub-tree when value is $delete' do
    loader = Loader.new(exit_on_fail: false)

    conf = loader.load(fixture_path('loader_test13.yml'))
    expect(conf).to eq(
      'bar' => 'str'
    )
  end
end
