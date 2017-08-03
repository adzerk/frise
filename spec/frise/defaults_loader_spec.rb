require 'frise/defaults_loader'

include Frise

RSpec.describe DefaultsLoader do
  it 'should merge correctly a file with plain default values' do
    conf = { 'a' => 45, 'str' => 'bcd' }
    conf = DefaultsLoader.merge_defaults(conf, fixture_path('simple.yml'))
    expect(conf).to eq('a' => 45, 'str' => 'bcd', 'int' => 4, 'bool' => true)
  end

  it 'should merge correctly default arrays and objects' do
    conf = {
      'arr' => ['elem2'],
      'obj' => { 'key2' => 'value02', 'key4' => 1 }
    }
    conf = DefaultsLoader.merge_defaults(conf, fixture_path('all_types.yml'))
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
    conf = DefaultsLoader.merge_defaults(conf,
                                         fixture_path('simple_liquid.yml'),
                                         'var1' => 'REPLACED', 'var2' => 1)
    expect(conf).to eq('a' => 45, 'str' => 'bcd', 'int' => 1, 'bool' => true)
  end

  it 'should interpret the $all key in a default object' do
    conf = { 'obj1' => {} }
    conf = DefaultsLoader.merge_defaults(conf, fixture_path('_defaults/all_specials.yml'))
    expect(conf['obj1']).to eq({})

    conf = {
      'obj1' => {
        'key1' => { 'i' => 1 },
        'key2' => { 'i' => 2 },
        'key3' => { 'i' => 3, 'enabled' => false }
      }
    }
    conf = DefaultsLoader.merge_defaults(conf, fixture_path('_defaults/all_specials.yml'))
    expect(conf['obj1']).to eq(
      'key1' => { 'i' => 1, 'enabled' => true },
      'key2' => { 'i' => 2, 'enabled' => true },
      'key3' => { 'i' => 3, 'enabled' => false }
    )
  end

  it 'should interpret the $optional key in a default object' do
    conf = DefaultsLoader.merge_defaults({}, fixture_path('_defaults/all_specials.yml'))
    expect(conf['obj2']).to eq nil

    conf = { 'obj2' => {} }
    conf = DefaultsLoader.merge_defaults(conf, fixture_path('_defaults/all_specials.yml'))
    expect(conf['obj2']).to eq('nest1' => { 'nest2' => 'val' })
  end

  it 'should merge correctly a file at a given path' do
    conf = { 'a' => 45, 'str' => 'bcd' }
    conf = DefaultsLoader.merge_defaults_at(conf, %w[new path], fixture_path('simple.yml'))
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
    expect { DefaultsLoader.merge_defaults(conf, fixture_path('simple.yml')) }
      .to raise_error 'Cannot merge config "not_an_int" (String) with default 4 (Integer)'
  end
end
