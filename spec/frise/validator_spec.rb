# frozen_string_literal: true

require 'frise/validator'

include Frise

def validate(config, schema, opts = {})
  Validator.validate(config, tmp_config_path(schema), opts)
end

def validate_at(config, at_path, schema, opts = {})
  Validator.validate_at(config, at_path, tmp_config_path(schema), opts)
end

RSpec.describe Validator do
  it 'should validate primitive types correctly' do
    schema = { 'int' => 'Integer', 'str' => 'String', 'bool' => 'Boolean', 'flt' => 'Float' }

    conf = { 'int' => 45, 'str' => 'abc', 'bool' => true, 'flt' => 4.5 }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = { 'int' => 4.5, 'str' => 3, 'bool' => 'true', 'flt' => 45 }
    errors = validate(conf, schema)
    expect(errors).to eq [
      'At int: expected Integer, found Float',
      'At str: expected String, found Integer',
      'At bool: expected Boolean, found String',
      'At flt: expected Float, found Integer'
    ]
  end

  it 'should raise an error if an invalid type is specified' do
    schema = { 'x' => 'InvalidType' }
    conf = { 'x' => 'str' }
    expect { validate(conf, schema) }
      .to raise_error('Invalid expected type in schema: InvalidType')
  end

  it 'should validate arrays correctly' do
    schema = { 'arr' => ['Integer'] }

    conf = { 'arr' => [45] }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = { 'arr' => [4.5] }
    errors = validate(conf, schema)
    expect(errors).to eq ['At arr.0: expected Integer, found Float']

    conf = { 'arr' => 45 }
    errors = validate(conf, schema)
    expect(errors).to eq ['At arr: expected Array, found Integer']
  end

  it 'should validate nested keys correctly' do
    schema = { 'obj' => { 'k0' => 'String' } }

    conf = { 'obj' => { 'k0' => 'abc' } }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = { 'obj' => { 'k0' => 1 } }
    errors = validate(conf, schema)
    expect(errors).to eq ['At obj.k0: expected String, found Integer']

    conf = { 'obj' => {} }
    errors = validate(conf, schema)
    expect(errors).to eq ['At obj.k0: missing required value']

    conf = {}
    errors = validate(conf, schema)
    expect(errors).to eq ['At obj: missing required value']
  end

  it 'should validate correctly missing values unless they are optional' do
    schema = { 'int' => 'Integer?', 'str' => 'String?', 'bool' => 'Boolean', 'flt' => 'Float' }

    conf = { 'int' => 45, 'str' => 'abc', 'bool' => true, 'flt' => 4.5 }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = { 'bool' => true, 'flt' => 4.5 }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = { 'int' => 45, 'str' => 'abc' }
    errors = validate(conf, schema)
    expect(errors).to eq [
      'At bool: missing required value',
      'At flt: missing required value'
    ]
  end

  it 'should validate that there are unknown keys unless $allow_unknown_keys is used' do
    schema1 = { 'int' => 'Integer', 'obj' => { 'str' => 'String' } }
    schema2 = { 'int' => 'Integer', 'obj' => { 'str' => 'String' }, '$allow_unknown_keys' => true }

    conf = { 'int' => 45, 'str' => 'abc', 'obj' => { 'str' => 'string' } }
    errors = validate(conf, schema1)
    expect(errors).to eq ['At <root>: unknown key: str']

    conf = { 'int' => 45, 'str' => 'abc', 'obj' => { 'str' => 'string' } }
    errors = validate(conf, schema2)
    expect(errors).to eq []

    conf = { 'int' => 45, 'obj' => { 'str' => 'string', 'str2' => 'something' } }
    errors = validate(conf, schema2)
    expect(errors).to eq ['At obj: unknown key: str2']
  end

  it 'should allow custom validations in schemas' do
    validators = Object.new
    def validators.even_int(_, n)
      (n.is_a?(Integer) && (n % 2).zero?) || (raise "expected an even number, found #{n}")
    end

    def validators.length_len(root, str)
      (str.is_a?(String) && str.size == root['len']) ||
        (raise "expected a string of length #{root['len']}, found #{str.inspect}")
    end

    schema = { 'len' => '$even_int', 'str' => '$length_len' }

    conf = { 'len' => 6, 'str' => 'abcdef' }
    errors = validate(conf, schema, validators: validators)
    expect(errors).to eq []

    conf = { 'len' => 5, 'str' => 'abcdef' }
    errors = validate(conf, schema, validators: validators)
    expect(errors).to eq [
      'At len: expected an even number, found 5',
      'At str: expected a string of length 5, found "abcdef"'
    ]
  end

  it 'should allow validations on all values of an object or array' do
    schema = {
      'arr' => { '$type' => 'Array', '$all' => { 'prop' => 'String' } },
      'obj' => { '$all' => { 'prop' => 'String' } }
    }

    conf = {
      'arr' => [{ 'prop' => 'p0' }, { 'prop' => 'p1' }],
      'obj' => { 'k0' => { 'prop' => 'p0' }, 'k1' => { 'prop' => 'p1' } }
    }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = {
      'arr' => [{ 'prop' => 'p0' }, { 'prop0' => 'p1' }],
      'obj' => { 'k0' => { 'prop' => 45 }, 'k1' => { 'prop' => 'p1' } }
    }
    errors = validate(conf, schema)
    expect(errors).to eq [
      'At arr.1.prop: missing required value',
      'At arr.1: unknown key: prop0',
      'At obj.k0.prop: expected String, found Integer'
    ]
  end

  it 'should allow validations on all keys of an object' do
    validators = Object.new
    def validators.short_string(_, str)
      (str.is_a?(String) && str.length < 5) || (raise "expected a short key, found #{str.inspect}")
    end

    schema = { 'obj' => { '$all_keys' => '$short_string', '$all' => 'String' } }

    conf = { 'obj' => { 'k0' => 'v0', 'k1' => 'v1' } }
    errors = validate(conf, schema, validators: validators)
    expect(errors).to eq []

    conf = { 'obj' => { 'objkey0' => 'v0', 'k1' => 'v1' } }
    errors = validate(conf, schema, validators: validators)
    expect(errors).to eq ['At obj: expected a short key, found "objkey0"']
  end

  it 'should validate correctly enumerations' do
    schema = { 'color' => { '$enum' => %w[red green blue] } }

    conf = { 'color' => 'green' }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = { 'color' => 'car' }
    errors = validate(conf, schema)
    expect(errors).to eq [
      'At color: invalid value "car". Accepted values are "red", "green", "blue"'
    ]
  end

  it 'should validate correctly $one_of choices of schemas' do
    schema = {
      'key' => {
        '$one_of' => ['String', { 'c' => 'Integer' }]
      }
    }

    conf = { 'key' => 'abc' }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = { 'key' => { 'c' => 4 } }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = { 'key' => 42 }
    errors = validate(conf, schema)
    expect(errors).to eq ['At key: 42 does not match any of the possible schemas']

    conf = { 'key' => { 'c' => 'abc' } }
    errors = validate(conf, schema)
    expect(errors).to eq ['At key: {"c"=>"abc"} does not match any of the possible schemas']
  end

  it 'should validate correctly $constant schemas' do
    schema = { 'key' => { '$constant' => 42 } }

    conf = { 'key' => 42 }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = { 'key' => 43 }
    errors = validate(conf, schema)
    expect(errors).to eq ['At key: invalid value 43. The only accepted value is 42']
  end

  it 'should make $constant schemas force values to be present' do
    schema = { 'key' => { '$constant' => 42 }, '$allow_unknown_keys' => true }

    conf = { 'other_key' => 42 }
    errors = validate(conf, schema)
    expect(errors).to eq ['At key: missing required value']
  end

  it 'should allow objects in $constant schemas' do
    schema = { 'key' => { '$constant' => { 'a' => 1, 'b' => 2 } } }

    conf = { 'key' => { 'b' => 2, 'a' => 1 } }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = { 'key' => { 'a' => 2, 'b' => 2 } }
    errors = validate(conf, schema)
    expect(errors).to eq ['At key: invalid value {"a"=>2, "b"=>2}. The only accepted value is {"a"=>1, "b"=>2}']
  end

  it 'should allow false values in $constant schemas' do
    schema = { 'key' => { '$constant' => false } }

    conf = { 'key' => false }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = { 'key' => true }
    errors = validate(conf, schema)
    expect(errors).to eq ['At key: invalid value true. The only accepted value is false']
  end

  it 'should allow falsey values in $constant schemas' do
    schema = { 'key1' => { '$constant' => 0 }, 'key2' => { '$constant' => '' } }

    conf = { 'key1' => 0, 'key2' => '' }
    errors = validate(conf, schema)
    expect(errors).to eq []

    conf = { 'key1' => 1, 'key2' => '' }
    errors = validate(conf, schema)
    expect(errors).to eq ['At key1: invalid value 1. The only accepted value is 0']
  end

  it 'should be able to use complex schemas in their full form' do
    validators = Object.new
    def validators.short_string(_, str)
      (str.is_a?(String) && str.length < 5) || (raise "expected a short string, found #{str.inspect}")
    end

    schema = {
      'opt_int_map' => { '$all_keys' => '$short_string', '$all' => 'Integer', '$optional' => true },
      'opt_sstr' => { '$type' => 'String', '$validate' => '$short_string', '$optional' => true },
      'opt_sstr_arr' => { '$type' => 'Array', '$all' => '$short_string', '$optional' => true },
      'sstr_arr' => ['$short_string'],
      'opt_enum' => { '$enum' => %w[a b c], '$optional' => true },
      'opt_one_of' => { '$one_of' => %w[String Integer], '$optional' => true }
    }

    conf = { 'sstr_arr' => ['val'] }
    errors = validate(conf, schema, validators: validators)
    expect(errors).to eq []

    conf = {
      'opt_int_map' => { 'k0' => 1, 'k1' => 'a', 'mapkey1' => 2 },
      'opt_sstr' => 'abcde',
      'opt_sstr_arr' => ['v1', 'v1234', true],
      'sstr_arr' => %w[value val],
      'opt_enum' => 'd',
      'opt_one_of' => 4.5
    }
    errors = validate(conf, schema, validators: validators)
    expect(errors).to eq [
      'At opt_int_map.k1: expected Integer, found String',
      'At opt_int_map: expected a short string, found "mapkey1"',
      'At opt_sstr: expected a short string, found "abcde"',
      'At opt_sstr_arr.1: expected a short string, found "v1234"',
      'At opt_sstr_arr.2: expected a short string, found true',
      'At sstr_arr.0: expected a short string, found "value"',
      'At opt_enum: invalid value "d". Accepted values are "a", "b", "c"',
      'At opt_one_of: 4.5 does not match any of the possible schemas'
    ]
  end

  it 'should validate correctly a config at a given path' do
    schema = { 'int' => 'Integer', 'str' => 'String', 'bool' => 'Boolean', 'flt' => 'Float' }

    conf = {
      'new' => {
        'path' => { 'int' => 45, 'str' => 'abc', 'bool' => true, 'flt' => 4.5 }
      }
    }
    errors = validate_at(conf, %w[new path], schema)
    expect(errors).to eq []

    conf = {
      'new' => {
        'path' => { 'str' => 'abc', 'bool' => true, 'flt' => 4.5 }
      }
    }
    errors = validate_at(conf, %w[new path], schema)
    expect(errors).to eq ['At new.path.int: missing required value']

    errors = validate_at({}, %w[new path], schema)
    expect(errors).to eq ['At new: missing required value']
  end

  it 'should raise an error if an invalid schema is specified' do
    schema1 = { 'x' => 4 }
    schema2 = { 'x' => %w[String Integer] }
    conf = { 'x' => 'str' }

    expect { validate(conf, schema1) }
      .to raise_error('Invalid schema: 4')
    expect { validate(conf, schema2) }
      .to raise_error('Invalid schema: ["String", "Integer"]')
  end

  it 'should raise an error on validation error if the option :raise_error is set' do
    schema = { 'obj' => { 'k0' => 'String' } }
    conf = { 'obj' => { 'k0' => 1 } }
    expect { validate(conf, schema, raise_error: true) }.to raise_error do |e|
      expect(e.message).to eq('Invalid configuration')
      expect(e.errors).to eq(['At obj.k0: expected String, found Integer'])
    end
  end

  it 'should print validation errors if the option :print is set' do
    schema = { 'obj' => { 'k0' => 'String' } }
    conf = { 'obj' => { 'k0' => 1 } }
    expect { validate(conf, schema, print: true) }.to output(
      "1 config error(s) found:\n" \
      " - At obj.k0: expected String, found Integer\n"
    ).to_stdout
  end

  it 'should terminate the program on validation error if the :fatal option is set' do
    schema = { 'obj' => { 'k0' => 'String' } }
    conf = { 'obj' => { 'k0' => 1 } }
    expect { validate(conf, schema, fatal: true) }.to raise_error(SystemExit)
  end
end
