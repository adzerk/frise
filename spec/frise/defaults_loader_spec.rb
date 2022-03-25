# frozen_string_literal: true

require 'frise/defaults_loader'

include Frise

RSpec.describe DefaultsLoader do
  it 'should merge correctly a file with plain default values' do
    conf = { 'a' => 45, 'str' => 'bcd' }
    conf = DefaultsLoader.new.merge_defaults(conf, fixture_path('simple.yml'))
    expect(conf).to eq('a' => 45, 'str' => 'bcd', 'int' => 4, 'bool' => true)
  end

  it 'should merge correctly default arrays and objects' do
    conf = {
      'arr' => ['elem2'],
      'obj' => { 'key2' => 'value02', 'key4' => 1 }
    }
    conf = DefaultsLoader.new.merge_defaults(conf, fixture_path('all_types.yml'))
    expect(conf['arr']).to eq %w[elem0 elem1 elem2]
    expect(conf['obj']).to eq(
      'key1' => 'value1',
      'key2' => 'value02',
      'key3' => { 'nested1' => 'nvalue1' },
      'key4' => 1
    )
  end

  it 'should merge files with Liquid templates if a symbol table is passed' do
    conf = { 'a' => 45, 'str' => 'bcd' }
    conf = DefaultsLoader.new.merge_defaults(conf,
                                             fixture_path('simple_liquid.yml'),
                                             'var1' => 'REPLACED', 'var2' => 1)
    expect(conf).to eq('a' => 45, 'str' => 'bcd', 'int' => 1, 'bool' => true)
  end

  it 'should interpret the $all key in a default hash or array' do
    conf = { 'obj1' => {}, 'arr' => [] }
    conf = DefaultsLoader.new.merge_defaults(conf, fixture_path('_defaults/all_specials.yml'))
    expect(conf['obj1']).to eq({})
    expect(conf['arr']).to eq([])

    conf = {
      'obj1' => {
        'key1' => { 'i' => 1 },
        'key2' => { 'i' => 2 },
        'key3' => { 'i' => 3, 'enabled' => false }
      },
      'arr' => [
        { 'j' => 1 },
        { 'j' => 2 },
        { 'j' => 3, 'active' => false }
      ]
    }
    conf = DefaultsLoader.new.merge_defaults(conf, fixture_path('_defaults/all_specials.yml'))
    expect(conf['obj1']).to eq(
      'key1' => { 'i' => 1, 'enabled' => true },
      'key2' => { 'i' => 2, 'enabled' => true },
      'key3' => { 'i' => 3, 'enabled' => false }
    )
    expect(conf['arr']).to eq(
      [
        { 'j' => 1, 'active' => true },
        { 'j' => 2, 'active' => true },
        { 'j' => 3, 'active' => false }
      ]
    )
  end

  it 'should interpret the $optional key in a default hash' do
    conf = DefaultsLoader.new.merge_defaults({}, fixture_path('_defaults/all_specials.yml'))
    expect(conf['obj2']).to eq nil

    conf = { 'obj2' => {} }
    conf = DefaultsLoader.new.merge_defaults(conf, fixture_path('_defaults/all_specials.yml'))
    expect(conf['obj2']).to eq('nest1' => { 'nest2' => 'val' })
  end

  it 'should merge correctly a file at a given path' do
    conf = { 'a' => 45, 'str' => 'bcd' }
    conf = DefaultsLoader.new.merge_defaults_at(conf, %w[new path], fixture_path('simple.yml'))
    expect(conf).to eq(
      'a' => 45,
      'str' => 'bcd',
      'new' => {
        'path' => { 'str' => 'abc', 'int' => 4, 'bool' => true }
      }
    )
  end

  it 'should raise an error when trying to merge defaults with different values' do
    conf = { 'int' => 'not_an_int' }
    expect { DefaultsLoader.new.merge_defaults(conf, fixture_path('simple.yml')) }
      .to raise_error 'Cannot merge config "not_an_int" (String) with default 4 (Integer)'

    conf = { 'int' => true }
    expect { DefaultsLoader.new.merge_defaults(conf, fixture_path('simple.yml')) }
      .to raise_error 'Cannot merge config true (Boolean) with default 4 (Integer)'
  end

  it 'should treat $content_include directives as string values' do
    conf = { 'str' => { '$content_include' => ['str.txt'] } }
    conf = DefaultsLoader.new.merge_defaults(conf, fixture_path('simple.yml'))
    expect(conf).to eq(
      'str' => { '$content_include' => ['str.txt'] },
      'int' => 4,
      'bool' => true
    )

    conf = { '$content_include' => ['str.txt'] }
    expect { DefaultsLoader.new.merge_defaults(conf, fixture_path('simple.yml')) }
      .to raise_error 'Cannot merge config {"$content_include"=>["str.txt"]} (String) ' \
                      'with default {"str"=>"abc", "int"=>4, "bool"=>true} (Hash)'
  end

  it 'should override defaults when value is $delete' do
    conf = {
      'str' => '$delete',
      'int' => '$delete',
      'bool' => '$delete',
      'arr' => '$delete',
      'another_arr' => ['$delete'], # has no effect inside an array
      'obj' => { 'key1' => '$delete', 'key3' => '$delete' }
    }
    loader = DefaultsLoader.new
    conf = loader.clear_delete_markers(loader.merge_defaults(conf, fixture_path('all_types.yml')))
    expect(conf.key?('str')).to be false
    expect(conf.key?('int')).to be false
    expect(conf.key?('bool')).to be false
    expect(conf.key?('arr')).to be false
    expect(conf['another_arr']).to eq(%w[elem0 elem1])
    expect(conf['obj']).to eq(
      'key2' => 'value2'
    )
  end
end
