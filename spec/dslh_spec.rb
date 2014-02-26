describe Dslh do
  it 'should be empty hash' do
    h = Dslh.eval {}
    expect(h).to eq({})
  end

  it 'should be hash' do
    h = Dslh.eval do
      key1 'value'
      key2 100
    end

    expect(h).to eq({
      :key1 => 'value',
      :key2 => 100,
    })
  end

  it 'should be nested hash' do
    h = Dslh.eval do
      key1 'value'
      key2 100

      key3 do
        key31 "value31" do
          key311 100
          key312 '200'
        end

        key32 do
          key321 "value321" do
            key3211 'XXX'
            key3212 :XXX
          end
          key322 300
        end
      end
    end

    expect(h).to eq(
      {:key1=>"value",
       :key2=>100,
       :key3=>
        {:key31=>{"value31"=>{:key311=>100, :key312=>"200"}},
         :key32=>
          {:key321=>{"value321"=>{:key3211=>"XXX", :key3212=>:XXX}}, :key322=>300}}}
    )
  end

  it 'can pass hash argument' do
    h = Dslh.eval do
      key1 'value'
      key2 100

      key3(
        100   => 200,
        'XXX' => :XXX
      )

      key4 do
        key41(
          '300' => '400',
          :FOO  => :BAR
        )
        key42 100
      end
    end

    expect(h).to eq(
      {:key1=>"value",
       :key2=>100,
       :key3=>{100=>200, "XXX"=>:XXX},
       :key4=>{:key41=>{"300"=>"400", :FOO=>:BAR}, :key42=>100}}
    )
  end

  it 'should convert hash key/value' do
    h = Dslh.eval :conv => proc {|i| i.to_s } do
      key1 'value'
      key2 100

      key3 do
        key31 "value31" do
          key311 100
          key312 '200'
        end

        key32 do
          key321 "value321" do
            key3211 'XXX'
            key3212 :XXX
          end
          key322 300
        end
      end
    end

    expect(h).to eq(
      {"key1"=>"value",
       "key2"=>"100",
       "key3"=>
        {"key31"=>{"value31"=>{"key311"=>"100", "key312"=>"200"}},
         "key32"=>
          {"key321"=>{"value321"=>{"key3211"=>"XXX", "key3212"=>"XXX"}},
           "key322"=>"300"}}}
    )
  end

  it 'should convert hash key' do
    h = Dslh.eval :key_conv => proc {|i| i.to_s } do
      key1 'value'
      key2 100

      key3 do
        key31 "value31" do
          key311 100
          key312 '200'
        end

        key32 do
          key321 "value321" do
            key3211 'XXX'
            key3212 :XXX
          end
          key322 300
        end
      end
    end

    expect(h).to eq(
      {"key1"=>"value",
       "key2"=>100,
       "key3"=>
        {"key31"=>{"value31"=>{"key311"=>100, "key312"=>"200"}},
         "key32"=>
          {"key321"=>{"value321"=>{"key3211"=>"XXX", "key3212"=>:XXX}},
           "key322"=>300}}}
    )
  end

  it 'should convert hash value' do
    h = Dslh.eval :value_conv => proc {|i| i.to_s } do
      key1 'value'
      key2 100

      key3 do
        key31 "value31" do
          key311 100
          key312 '200'
        end

        key32 do
          key321 "value321" do
            key3211 'XXX'
            key3212 :XXX
          end
          key322 300
        end
      end
    end

    expect(h).to eq(
      {:key1=>"value",
       :key2=>"100",
       :key3=>
        {:key31=>{"value31"=>{:key311=>"100", :key312=>"200"}},
         :key32=>
          {:key321=>{"value321"=>{:key3211=>"XXX", :key3212=>"XXX"}},
           :key322=>"300"}}}
    )
  end

  it 'can pass multiple argument' do
    h = Dslh.eval do
      key1 'value', 'value2'
      key2 100, 200

      key3 do
        key31 :FOO, :BAR
        key32 'ZOO', 'BAZ'
      end

      key4 'value4', 'value42' do
        key41 100
        key42 '200'
      end
    end

    expect(h).to eq(
      {:key1=>["value", "value2"],
       :key2=>[100, 200],
       :key3=>{:key31=>[:FOO, :BAR], :key32=>["ZOO", "BAZ"]},
       :key4=>{["value4", "value42"]=>{:key41=>100, :key42=>"200"}}}
    )
  end

  it 'should evalute string' do
    expr = <<-EOS
      key1 'value'
      key2 100

      key3 do
        key31 "value31" do
          key311 100
          key312 '200'
        end

        key32 do
          key321 "value321" do
            key3211 'XXX'
            key3212 :XXX
          end
          key322 300
        end
      end
    EOS

    h = Dslh.eval(expr)

    expect(h).to eq(
      {:key1=>"value",
       :key2=>100,
       :key3=>
        {:key31=>{"value31"=>{:key311=>100, :key312=>"200"}},
         :key32=>
          {:key321=>{"value321"=>{:key3211=>"XXX", :key3212=>:XXX}}, :key322=>300}}}
    )
  end

  it 'should evalute string with filename/lineno' do
    expr = <<-EOS
      key1 'value'
      key2 100

      key3 do
        key31 "value31" do
          key311 100
          key312 '200'
        end

        key32 do
          key321 "value321" do
            key3211 'XXX'
            key3212 :XXX
          end
          key322 300
        end
      end
    EOS

    h = Dslh.eval(expr, :filename => 'my.rb', :lineno => 100)

    expect(h).to eq(
      {:key1=>"value",
       :key2=>100,
       :key3=>
        {:key31=>{"value31"=>{:key311=>100, :key312=>"200"}},
         :key32=>
          {:key321=>{"value321"=>{:key3211=>"XXX", :key3212=>:XXX}}, :key322=>300}}}
    )
  end

  it 'should convert array' do
    h = Dslh.eval :value_conv => proc {|i| i.to_s } do
      key1 'value1', 'value2'
      key2 100, 200
    end

    expect(h).to eq(
      {:key1 => ["value1", "value2"],
       :key2 => ["100", "200"]}
    )
  end
end
