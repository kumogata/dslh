describe Dslh do
  let(:drupal_multi_az_template) do
    open(File.expand_path('../Drupal_Multi_AZ.template', __FILE__)) {|f| f.read }
  end

  let(:drupal_single_instance_template) do
    open(File.expand_path('../Drupal_Single_Instance.template', __FILE__)) {|f| f.read }
  end

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

  it 'should be nested hash with _()' do
    h = Dslh.eval do
      key1 'value'
      key2 100

      _(:key3) do
        _(:key31) do
          key311 100
          key312 '200'
        end

        _('key32') do
          key321 do
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
        {:key31=>{:key311=>100, :key312=>"200"},
         'key32'=>
          {:key321=>{:key3211=>"XXX", :key3212=>:XXX}, :key322=>300}}}
    )
  end

  it 'should be nested hash with block args' do
    h = Dslh.eval do
      key1 'value'
      key2 100

      key3 do |a1|
        key31 "value31" do |a2|
          key311 100
          key312 "200 #{a1} #{a2}"
        end

        key32 do |a3|
          key321 "value321" do |a4|
            key3211 "XXX #{a1} #{a3} #{a4}"
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
        {:key31=>{"value31"=>{:key311=>100, :key312=>"200 key3 key31"}},
         :key32=>
          {:key321=>{"value321"=>{:key3211=>"XXX key3 key32 key321", :key3212=>:XXX}}, :key322=>300}}}
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

  it 'should share context' do
    h = Dslh.eval :value_conv => proc {|i| i.to_s } do
      def func
        123
      end

      var1 = 'FOO'
      var2 = 'BAR'
      var3 = 'ZOO'

      key1 func
      key2 do
        key21 func
        key22 do
          key221 func
          key222 var1
        end
        key23 var2
      end
      key3 var3
    end

    expect(h).to eq(
      {:key1=>"123",
       :key2=>
        {:key21=>"123", :key22=>{:key221=>"123", :key222=>"FOO"}, :key23=>"BAR"},
       :key3=>"ZOO"}
    )
  end

  it 'should hook scope' do
    scope_hook = proc do |scope|
      scope.instance_eval(<<-EOS)
        def func
          123
        end
      EOS
    end

    h = Dslh.eval :scope_hook => scope_hook do
      key1 func
      key2 do
        key21 func
        key22 do
          key221 func
        end
      end
    end

    expect(h).to eq({:key1=>123, :key2=>{:key21=>123, :key22=>{:key221=>123}}})
  end

  it 'should convert hash to dsl' do
    h = {"glossary"=>
          {"title"=>"example glossary",
           "GlossDiv"=>
            {"title"=>"S",
             "GlossList"=>
              {"GlossEntry"=>
                {"ID"=>"SGML",
                 "SortAs"=>"SGML",
                 "GlossTerm"=>"Standard Generalized Markup Language",
                 "Acronym"=>"SGML",
                 "Abbrev"=>"ISO 8879:1986",
                 "GlossDef"=>
                  {"para"=>
                    "A meta-markup language, used to create markup languages such as DocBook.",
                   "GlossSeeAlso"=>["GML", "XML"]},
                 "GlossSee"=>"markup"}}}}}

    dsl = Dslh.deval(h)
    expect(dsl).to eq(<<-EOS)
glossary do
  title "example glossary"
  GlossDiv do
    title "S"
    GlossList do
      GlossEntry do
        ID "SGML"
        SortAs "SGML"
        GlossTerm "Standard Generalized Markup Language"
        Acronym "SGML"
        Abbrev "ISO 8879:1986"
        GlossDef do
          para "A meta-markup language, used to create markup languages such as DocBook."
          GlossSeeAlso "GML", "XML"
        end
        GlossSee "markup"
      end
    end
  end
end
    EOS
  end

  it 'should convert hash to dsl with conv' do
    h = {"glossary"=>
          {"title"=>"example glossary",
           "GlossDiv"=>
            {"title"=>"S",
             "GlossList"=>
              {"GlossEntry"=>
                {"ID"=>"SGML",
                 "SortAs"=>"SGML",
                 "GlossTerm"=>"Standard Generalized Markup Language",
                 "Acronym"=>"SGML",
                 "Abbrev"=>"ISO 8879:1986",
                 "GlossDef"=>
                  {"para"=>
                    "A meta-markup language, used to create markup languages such as DocBook.",
                   "GlossSeeAlso"=>["GML", "XML"]},
                 "GlossSee"=>"markup"}}}}}

    dsl = Dslh.deval(h, :conv => proc {|i| i.to_s.upcase })
    expect(dsl).to eq(<<-EOS)
GLOSSARY do
  TITLE "EXAMPLE GLOSSARY"
  GLOSSDIV do
    TITLE "S"
    GLOSSLIST do
      GLOSSENTRY do
        ID "SGML"
        SORTAS "SGML"
        GLOSSTERM "STANDARD GENERALIZED MARKUP LANGUAGE"
        ACRONYM "SGML"
        ABBREV "ISO 8879:1986"
        GLOSSDEF do
          PARA "A META-MARKUP LANGUAGE, USED TO CREATE MARKUP LANGUAGES SUCH AS DOCBOOK."
          GLOSSSEEALSO "GML", "XML"
        end
        GLOSSSEE "MARKUP"
      end
    end
  end
end
    EOS
  end

  it 'should convert hash to dsl with key_conv' do
    h = {"glossary"=>
          {"title"=>"example glossary",
           "GlossDiv"=>
            {"title"=>"S",
             "GlossList"=>
              {"GlossEntry"=>
                {"ID"=>"SGML",
                 "SortAs"=>"SGML",
                 "GlossTerm"=>"Standard Generalized Markup Language",
                 "Acronym"=>"SGML",
                 "Abbrev"=>"ISO 8879:1986",
                 "GlossDef"=>
                  {"para"=>
                    "A meta-markup language, used to create markup languages such as DocBook.",
                   "GlossSeeAlso"=>["GML", "XML"]},
                 "GlossSee"=>"markup"}}}}}

    dsl = Dslh.deval(h, :key_conv => proc {|i| i.to_s.upcase })
    expect(dsl).to eq(<<-EOS)
GLOSSARY do
  TITLE "example glossary"
  GLOSSDIV do
    TITLE "S"
    GLOSSLIST do
      GLOSSENTRY do
        ID "SGML"
        SORTAS "SGML"
        GLOSSTERM "Standard Generalized Markup Language"
        ACRONYM "SGML"
        ABBREV "ISO 8879:1986"
        GLOSSDEF do
          PARA "A meta-markup language, used to create markup languages such as DocBook."
          GLOSSSEEALSO "GML", "XML"
        end
        GLOSSSEE "markup"
      end
    end
  end
end
    EOS
  end

  it 'does not allow duplicate key' do
    expect {
      Dslh.eval do
        key1 'value'
        key2 100

        key2 do
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
    }.to raise_error('duplicate key :key2')

    expect {
      Dslh.eval do
        key1 'value'
        key2 100

        key3 do
          key31 "value31" do
            key311 100
            key312 '200'
          end

          key31 do
            key321 "value321" do
              key3211 'XXX'
              key3212 :XXX
            end
            key322 300
          end
        end
      end
    }.to raise_error('duplicate key :key31')

    expect {
      Dslh.eval do
        key1 'value'
        key2 100

        key3 do
          key31 "value31" do
            key311 100
            key311 '200'
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
    }.to raise_error('duplicate key :key311')
  end

  it 'should convert hash to dsl with value_conv' do
    h = {"glossary"=>
          {"title"=>"example glossary",
           "GlossDiv"=>
            {"title"=>"S",
             "GlossList"=>
              {"GlossEntry"=>
                {"ID"=>"SGML",
                 "SortAs"=>"SGML",
                 "GlossTerm"=>"Standard Generalized Markup Language",
                 "Acronym"=>"SGML",
                 "Abbrev"=>"ISO 8879:1986",
                 "GlossDef"=>
                  {"para"=>
                    "A meta-markup language, used to create markup languages such as DocBook.",
                   "GlossSeeAlso"=>["GML", "XML"]},
                 "GlossSee"=>"markup"}}}}}

    dsl = Dslh.deval(h, :value_conv => proc {|i| i.to_s.upcase })
    expect(dsl).to eq(<<-EOS)
glossary do
  title "EXAMPLE GLOSSARY"
  GlossDiv do
    title "S"
    GlossList do
      GlossEntry do
        ID "SGML"
        SortAs "SGML"
        GlossTerm "STANDARD GENERALIZED MARKUP LANGUAGE"
        Acronym "SGML"
        Abbrev "ISO 8879:1986"
        GlossDef do
          para "A META-MARKUP LANGUAGE, USED TO CREATE MARKUP LANGUAGES SUCH AS DOCBOOK."
          GlossSeeAlso "GML", "XML"
        end
        GlossSee "MARKUP"
      end
    end
  end
end
    EOS
  end

  it 'should convert json to dsl' do
    template = JSON.parse(drupal_multi_az_template)

    dsl = Dslh.deval(template)
    evaluated = Dslh.eval(dsl, :key_conv => proc {|i| i.to_s })
    expect(evaluated).to eq(template)
  end

  it 'should convert json to dsl with key_conf' do
    template = JSON.parse(drupal_multi_az_template)

    key_conv = proc do |k|
      k.to_s.gsub('::', '__')
    end

    dsl = Dslh.deval(template, :key_conv => key_conv)

    expect(dsl).to eq(<<-'EOS')
AWSTemplateFormatVersion "2010-09-09"
Description "AWS CloudFormation Sample Template Drupal_Multi_AZ. Drupal is an open source content management platform powering millions of websites and applications. This template installs a highly-available, scalable Drupal deployment using a multi-az Amazon RDS database instance for storage. It uses the AWS CloudFormation bootstrap scripts to install packages and files at instance launch time. **WARNING** This template creates one or more Amazon EC2 instances, an Elastic Load Balancer and an Amazon RDS database. You will be billed for the AWS resources used if you create a stack from this template."
Parameters do
  KeyName do
    Description "Name of an existing EC2 KeyPair to enable SSH access to the instances"
    Type "String"
    MinLength "1"
    MaxLength "255"
    AllowedPattern "[\\x20-\\x7E]*"
    ConstraintDescription "can contain only ASCII characters."
  end
  InstanceType do
    Description "WebServer EC2 instance type"
    Type "String"
    Default "m1.small"
    ConstraintDescription "must be a valid EC2 instance type."
  end
  SiteName do
    Default "My Site"
    Description "The name of the Drupal Site"
    Type "String"
  end
  SiteEMail do
    Description "EMail for site adminitrator"
    Type "String"
  end
  SiteAdmin do
    Description "The Drupal site admin account username"
    Type "String"
    MinLength "1"
    MaxLength "16"
    AllowedPattern "[a-zA-Z][a-zA-Z0-9]*"
    ConstraintDescription "must begin with a letter and contain only alphanumeric characters."
  end
  SitePassword do
    NoEcho "true"
    Description "The Drupal site admin account password"
    Type "String"
    MinLength "1"
    MaxLength "41"
    AllowedPattern "[a-zA-Z0-9]*"
    ConstraintDescription "must contain only alphanumeric characters."
  end
  DBName do
    Default "drupaldb"
    Description "The Drupal database name"
    Type "String"
    MinLength "1"
    MaxLength "64"
    AllowedPattern "[a-zA-Z][a-zA-Z0-9]*"
    ConstraintDescription "must begin with a letter and contain only alphanumeric characters."
  end
  DBUsername do
    Default "admin"
    NoEcho "true"
    Description "The Drupal database admin account username"
    Type "String"
    MinLength "1"
    MaxLength "16"
    AllowedPattern "[a-zA-Z][a-zA-Z0-9]*"
    ConstraintDescription "must begin with a letter and contain only alphanumeric characters."
  end
  DBPassword do
    Default "password"
    NoEcho "true"
    Description "The Drupal database admin account password"
    Type "String"
    MinLength "8"
    MaxLength "41"
    AllowedPattern "[a-zA-Z0-9]*"
    ConstraintDescription "must contain only alphanumeric characters."
  end
  DBClass do
    Default "db.m1.small"
    Description "Database instance class"
    Type "String"
    AllowedValues "db.m1.small", "db.m1.large", "db.m1.xlarge", "db.m2.xlarge", "db.m2.2xlarge", "db.m2.4xlarge"
    ConstraintDescription "must select a valid database instance type."
  end
  DBAllocatedStorage do
    Default "5"
    Description "The size of the database (Gb)"
    Type "Number"
    MinValue "5"
    MaxValue "1024"
    ConstraintDescription "must be between 5 and 1024Gb."
  end
  MultiAZDatabase do
    Default "true"
    Description "Create a multi-AZ MySQL Amazon RDS database instance"
    Type "String"
    AllowedValues "true", "false"
    ConstraintDescription "must be either true or false."
  end
  WebServerCapacity do
    Default "2"
    Description "The initial number of WebServer instances"
    Type "Number"
    MinValue "1"
    MaxValue "5"
    ConstraintDescription "must be between 1 and 5 EC2 instances."
  end
  SSHLocation do
    Description "The IP address range that can be used to SSH to the EC2 instances"
    Type "String"
    MinLength "9"
    MaxLength "18"
    Default "0.0.0.0/0"
    AllowedPattern "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
    ConstraintDescription "must be a valid IP CIDR range of the form x.x.x.x/x."
  end
end
Mappings do
  AWSInstanceType2Arch(
    {"t1.micro"=>{"Arch"=>"64"},
     "m1.small"=>{"Arch"=>"64"},
     "m1.medium"=>{"Arch"=>"64"},
     "m1.large"=>{"Arch"=>"64"},
     "m1.xlarge"=>{"Arch"=>"64"},
     "m2.xlarge"=>{"Arch"=>"64"},
     "m2.2xlarge"=>{"Arch"=>"64"},
     "m2.4xlarge"=>{"Arch"=>"64"},
     "m3.xlarge"=>{"Arch"=>"64"},
     "m3.2xlarge"=>{"Arch"=>"64"},
     "c1.medium"=>{"Arch"=>"64"},
     "c1.xlarge"=>{"Arch"=>"64"},
     "cc1.4xlarge"=>{"Arch"=>"64HVM"},
     "cc2.8xlarge"=>{"Arch"=>"64HVM"},
     "cg1.4xlarge"=>{"Arch"=>"64HVM"}})
  AWSRegionArch2AMI(
    {"us-east-1"=>
      {"32"=>"ami-a0cd60c9", "64"=>"ami-aecd60c7", "64HVM"=>"ami-a8cd60c1"},
     "us-west-2"=>
      {"32"=>"ami-46da5576", "64"=>"ami-48da5578", "64HVM"=>"NOT_YET_SUPPORTED"},
     "us-west-1"=>
      {"32"=>"ami-7d4c6938", "64"=>"ami-734c6936", "64HVM"=>"NOT_YET_SUPPORTED"},
     "eu-west-1"=>
      {"32"=>"ami-61555115", "64"=>"ami-6d555119", "64HVM"=>"ami-67555113"},
     "ap-southeast-1"=>
      {"32"=>"ami-220b4a70", "64"=>"ami-3c0b4a6e", "64HVM"=>"NOT_YET_SUPPORTED"},
     "ap-southeast-2"=>
      {"32"=>"ami-8f990eb5", "64"=>"ami-95990eaf", "64HVM"=>"NOT_YET_SUPPORTED"},
     "ap-northeast-1"=>
      {"32"=>"ami-2a19aa2b", "64"=>"ami-2819aa29", "64HVM"=>"NOT_YET_SUPPORTED"},
     "sa-east-1"=>
      {"32"=>"ami-f836e8e5", "64"=>"ami-fe36e8e3", "64HVM"=>"NOT_YET_SUPPORTED"}})
end
Resources do
  S3Bucket do
    Type "AWS::S3::Bucket"
    DeletionPolicy "Retain"
  end
  BucketPolicy do
    Type "AWS::S3::BucketPolicy"
    Properties do
      PolicyDocument do
        Version "2008-10-17"
        Id "UploadPolicy"
        Statement [
          _{
            Sid "EnableReadWrite"
            Action "s3:GetObject", "s3:PutObject", "s3:PutObjectACL"
            Effect "Allow"
            Resource do
              Fn__Join [
                "",
                [
                  "arn:aws:s3:::",
                  _{
                    Ref "S3Bucket"
                  },
                  "/*"
                ]
              ]
            end
            Principal do
              AWS do
                Fn__GetAtt "S3User", "Arn"
              end
            end
          }
        ]
      end
      Bucket do
        Ref "S3Bucket"
      end
    end
  end
  S3User do
    Type "AWS::IAM::User"
    Properties do
      Path "/"
      Policies [
        _{
          PolicyName "root"
          PolicyDocument do
            Statement [
              _{
                Effect "Allow"
                Action "s3:*"
                Resource "*"
              }
            ]
          end
        }
      ]
    end
  end
  S3Keys do
    Type "AWS::IAM::AccessKey"
    Properties do
      UserName do
        Ref "S3User"
      end
    end
  end
  ElasticLoadBalancer do
    Type "AWS::ElasticLoadBalancing::LoadBalancer"
    Metadata do
      Comment "Configure the Load Balancer with a simple health check and cookie-based stickiness"
    end
    Properties do
      AvailabilityZones do
        Fn__GetAZs ""
      end
      LBCookieStickinessPolicy [
        _{
          PolicyName "CookieBasedPolicy"
          CookieExpirationPeriod "30"
        }
      ]
      Listeners [
        _{
          LoadBalancerPort "80"
          InstancePort "80"
          Protocol "HTTP"
          PolicyNames ["CookieBasedPolicy"]
        }
      ]
      HealthCheck do
        Target "HTTP:80/"
        HealthyThreshold "2"
        UnhealthyThreshold "5"
        Interval "10"
        Timeout "5"
      end
    end
  end
  WebServerGroup do
    Type "AWS::AutoScaling::AutoScalingGroup"
    Properties do
      AvailabilityZones do
        Fn__GetAZs ""
      end
      LaunchConfigurationName do
        Ref "LaunchConfig"
      end
      MinSize "1"
      MaxSize "5"
      DesiredCapacity do
        Ref "WebServerCapacity"
      end
      LoadBalancerNames [
        _{
          Ref "ElasticLoadBalancer"
        }
      ]
    end
  end
  LaunchConfig do
    Type "AWS::AutoScaling::LaunchConfiguration"
    Metadata do
      AWS__CloudFormation__Init do
        config do
          packages do
            yum(
              {"httpd"=>[],
               "php"=>[],
               "php-mysql"=>[],
               "php-gd"=>[],
               "php-xml"=>[],
               "php-mbstring"=>[],
               "mysql"=>[],
               "gcc"=>[],
               "make"=>[],
               "libstdc++-devel"=>[],
               "gcc-c++"=>[],
               "fuse"=>[],
               "fuse-devel"=>[],
               "libcurl-devel"=>[],
               "libxml2-devel"=>[],
               "openssl-devel"=>[],
               "mailcap"=>[]})
          end
          sources(
            {"/var/www/html"=>"http://ftp.drupal.org/files/projects/drupal-7.8.tar.gz",
             "/home/ec2-user"=>"http://ftp.drupal.org/files/projects/drush-7.x-4.5.tar.gz",
             "/home/ec2-user/s3fs"=>"http://s3fs.googlecode.com/files/s3fs-1.61.tar.gz"})
          files(
            {"/etc/passwd-s3fs"=>
              {"content"=>
                {"Fn::Join"=>
                  ["",
                   [{"Ref"=>"S3Keys"},
                    ":",
                    {"Fn::GetAtt"=>["S3Keys", "SecretAccessKey"]},
                    "\n"]]},
               "mode"=>"000400",
               "owner"=>"root",
               "group"=>"root"},
             "/home/ec2-user/settings.php"=>
              {"content"=>
                {"Fn::Join"=>
                  ["",
                   ["<?php\n",
                    "\n",
                    "$databases = array (\n",
                    "  'default' =>\n",
                    "  array (\n",
                    "    'default' =>\n",
                    "    array (\n",
                    "      'database' => '",
                    {"Ref"=>"DBName"},
                    "',\n",
                    "      'username' => '",
                    {"Ref"=>"DBUsername"},
                    "',\n",
                    "      'password' => '",
                    {"Ref"=>"DBPassword"},
                    "',\n",
                    "      'host' => '",
                    {"Fn::GetAtt"=>["DBInstance", "Endpoint.Address"]},
                    "',\n",
                    "      'port' => '",
                    {"Fn::GetAtt"=>["DBInstance", "Endpoint.Port"]},
                    "',\n",
                    "      'driver' => 'mysql',\n",
                    "      'prefix' => 'drupal_',\n",
                    "    ),\n",
                    "  ),\n",
                    ");\n",
                    "\n",
                    "$update_free_access = FALSE;\n",
                    "\n",
                    "$drupal_hash_salt = '0c3R8noNALe3shsioQr5hK1dMHdwRfikLoSfqn0_xpA';\n",
                    "\n",
                    "ini_set('session.gc_probability', 1);\n",
                    "ini_set('session.gc_divisor', 100);\n",
                    "ini_set('session.gc_maxlifetime', 200000);\n",
                    "ini_set('session.cookie_lifetime', 2000000);\n"]]},
               "mode"=>"000400",
               "owner"=>"root",
               "group"=>"root"}})
          services do
            sysvinit do
              httpd do
                enabled "true"
                ensureRunning "true"
              end
              sendmail do
                enabled "false"
                ensureRunning "false"
              end
            end
          end
        end
      end
    end
    Properties do
      ImageId do
        Fn__FindInMap [
          "AWSRegionArch2AMI",
          _{
            Ref "AWS::Region"
          },
          _{
            Fn__FindInMap [
              "AWSInstanceType2Arch",
              _{
                Ref "InstanceType"
              },
              "Arch"
            ]
          }
        ]
      end
      InstanceType do
        Ref "InstanceType"
      end
      SecurityGroups [
        _{
          Ref "WebServerSecurityGroup"
        }
      ]
      KeyName do
        Ref "KeyName"
      end
      UserData do
        Fn__Base64 do
          Fn__Join [
            "",
            [
              "#!/bin/bash -v\n",
              "yum update -y aws-cfn-bootstrap\n",
              "# Helper function\n",
              "function error_exit\n",
              "{\n",
              "  /opt/aws/bin/cfn-signal -e 1 -r \"$1\" '",
              _{
                Ref "WaitHandle"
              },
              "'\n",
              "  exit 1\n",
              "}\n",
              "# Install Apache Web Server, MySQL and Drupal\n",
              "/opt/aws/bin/cfn-init -s ",
              _{
                Ref "AWS::StackId"
              },
              " -r LaunchConfig ",
              "    --region ",
              _{
                Ref "AWS::Region"
              },
              " || error_exit 'Failed to run cfn-init'\n",
              "# Install s3fs\n",
              "cd /home/ec2-user/s3fs/s3fs-1.61\n",
              "./configure --prefix=/usr\n",
              "make\n",
              "make install\n",
              "# Move the website files to the top level\n",
              "mv /var/www/html/drupal-7.8/* /var/www/html\n",
              "mv /var/www/html/drupal-7.8/.htaccess /var/www/html\n",
              "rm -Rf /var/www/html/drupal-7.8\n",
              "# Mount the S3 bucket\n",
              "mv /var/www/html/sites/default/files /var/www/html/sites/default/files_original\n",
              "mkdir -p /var/www/html/sites/default/files\n",
              "s3fs -o allow_other -o use_cache=/tmp ",
              _{
                Ref "S3Bucket"
              },
              " /var/www/html/sites/default/files || error_exit 'Failed to mount the S3 bucket'\n",
              "echo `hostname` >> /var/www/html/sites/default/files/hosts\n",
              "# Make changes to Apache Web Server configuration\n",
              "sed -i 's/AllowOverride None/AllowOverride All/g'  /etc/httpd/conf/httpd.conf\n",
              "service httpd restart\n",
              "# Only execute the site install if we are the first host up - otherwise we'll end up losing all the data\n",
              "read first < /var/www/html/sites/default/files/hosts\n",
              "if [ `hostname` = $first ]\n",
              "then\n",
              "  # Create the site in Drupal\n",
              "  cd /var/www/html\n",
              "  ~ec2-user/drush/drush site-install standard --yes",
              "     --site-name='",
              _{
                Ref "SiteName"
              },
              "' --site-mail=",
              _{
                Ref "SiteEMail"
              },
              "     --account-name=",
              _{
                Ref "SiteAdmin"
              },
              " --account-pass=",
              _{
                Ref "SitePassword"
              },
              "     --db-url=mysql://",
              _{
                Ref "DBUsername"
              },
              ":",
              _{
                Ref "DBPassword"
              },
              "@",
              _{
                Fn__GetAtt "DBInstance", "Endpoint.Address"
              },
              ":",
              _{
                Fn__GetAtt "DBInstance", "Endpoint.Port"
              },
              "/",
              _{
                Ref "DBName"
              },
              "     --db-prefix=drupal_\n",
              "  # use the S3 bucket for shared file storage\n",
              "  cp -R sites/default/files_original/* sites/default/files\n",
              "  cp -R sites/default/files_original/.htaccess sites/default/files\n",
              "else\n",
              "  # Copy settings.php file since everything else is configured\n",
              "  cp /home/ec2-user/settings.php /var/www/html/sites/default\n",
              "fi\n",
              "rm /home/ec2-user/settings.php\n",
              "# All is well so signal success\n",
              "/opt/aws/bin/cfn-signal -e 0 -r \"Drupal setup complete\" '",
              _{
                Ref "WaitHandle"
              },
              "'\n"
            ]
          ]
        end
      end
    end
  end
  WaitHandle do
    Type "AWS::CloudFormation::WaitConditionHandle"
  end
  WaitCondition do
    Type "AWS::CloudFormation::WaitCondition"
    DependsOn "WebServerGroup"
    Properties do
      Handle do
        Ref "WaitHandle"
      end
      Timeout "600"
    end
  end
  DBInstance do
    Type "AWS::RDS::DBInstance"
    Properties do
      DBName do
        Ref "DBName"
      end
      Engine "MySQL"
      MultiAZ do
        Ref "MultiAZDatabase"
      end
      MasterUsername do
        Ref "DBUsername"
      end
      DBInstanceClass do
        Ref "DBClass"
      end
      DBSecurityGroups [
        _{
          Ref "DBSecurityGroup"
        }
      ]
      AllocatedStorage do
        Ref "DBAllocatedStorage"
      end
      MasterUserPassword do
        Ref "DBPassword"
      end
    end
  end
  DBSecurityGroup do
    Type "AWS::RDS::DBSecurityGroup"
    Properties do
      DBSecurityGroupIngress do
        EC2SecurityGroupName do
          Ref "WebServerSecurityGroup"
        end
      end
      GroupDescription "Frontend Access"
    end
  end
  WebServerSecurityGroup do
    Type "AWS::EC2::SecurityGroup"
    Properties do
      GroupDescription "Enable HTTP access via port 80, locked down to requests from the load balancer only and SSH access"
      SecurityGroupIngress [
        _{
          IpProtocol "tcp"
          FromPort "80"
          ToPort "80"
          SourceSecurityGroupOwnerId do
            Fn__GetAtt "ElasticLoadBalancer", "SourceSecurityGroup.OwnerAlias"
          end
          SourceSecurityGroupName do
            Fn__GetAtt "ElasticLoadBalancer", "SourceSecurityGroup.GroupName"
          end
        },
        _{
          IpProtocol "tcp"
          FromPort "22"
          ToPort "22"
          CidrIp do
            Ref "SSHLocation"
          end
        }
      ]
    end
  end
end
Outputs do
  WebsiteURL do
    Value do
      Fn__Join [
        "",
        [
          "http://",
          _{
            Fn__GetAtt "ElasticLoadBalancer", "DNSName"
          }
        ]
      ]
    end
    Description "Drupal Website"
  end
end
    EOS
  end

  it 'should convert json to dsl with key_conf (return Proc)' do
    template = JSON.parse(drupal_multi_az_template)

    exclude_key = proc do |k|
      k = k.to_s.gsub('::', '__')
      k !~ /\A[_a-z]\w+\Z/i and k !~ %r|\A/\S*\Z|
    end

    key_conv = proc do |k|
      k = k.to_s

      if k =~ %r|\A/\S*\Z|
        proc do |v, nested|
          if nested
            "_path(#{k.inspect}) #{v}"
          else
            "_path #{k.inspect}, #{v}"
          end
        end
      else
        k.gsub('::', '__')
      end
    end

    dsl = Dslh.deval(template, :key_conv => key_conv, :exclude_key => exclude_key)

    expect(dsl).to eq(<<-'EOS')
AWSTemplateFormatVersion "2010-09-09"
Description "AWS CloudFormation Sample Template Drupal_Multi_AZ. Drupal is an open source content management platform powering millions of websites and applications. This template installs a highly-available, scalable Drupal deployment using a multi-az Amazon RDS database instance for storage. It uses the AWS CloudFormation bootstrap scripts to install packages and files at instance launch time. **WARNING** This template creates one or more Amazon EC2 instances, an Elastic Load Balancer and an Amazon RDS database. You will be billed for the AWS resources used if you create a stack from this template."
Parameters do
  KeyName do
    Description "Name of an existing EC2 KeyPair to enable SSH access to the instances"
    Type "String"
    MinLength "1"
    MaxLength "255"
    AllowedPattern "[\\x20-\\x7E]*"
    ConstraintDescription "can contain only ASCII characters."
  end
  InstanceType do
    Description "WebServer EC2 instance type"
    Type "String"
    Default "m1.small"
    ConstraintDescription "must be a valid EC2 instance type."
  end
  SiteName do
    Default "My Site"
    Description "The name of the Drupal Site"
    Type "String"
  end
  SiteEMail do
    Description "EMail for site adminitrator"
    Type "String"
  end
  SiteAdmin do
    Description "The Drupal site admin account username"
    Type "String"
    MinLength "1"
    MaxLength "16"
    AllowedPattern "[a-zA-Z][a-zA-Z0-9]*"
    ConstraintDescription "must begin with a letter and contain only alphanumeric characters."
  end
  SitePassword do
    NoEcho "true"
    Description "The Drupal site admin account password"
    Type "String"
    MinLength "1"
    MaxLength "41"
    AllowedPattern "[a-zA-Z0-9]*"
    ConstraintDescription "must contain only alphanumeric characters."
  end
  DBName do
    Default "drupaldb"
    Description "The Drupal database name"
    Type "String"
    MinLength "1"
    MaxLength "64"
    AllowedPattern "[a-zA-Z][a-zA-Z0-9]*"
    ConstraintDescription "must begin with a letter and contain only alphanumeric characters."
  end
  DBUsername do
    Default "admin"
    NoEcho "true"
    Description "The Drupal database admin account username"
    Type "String"
    MinLength "1"
    MaxLength "16"
    AllowedPattern "[a-zA-Z][a-zA-Z0-9]*"
    ConstraintDescription "must begin with a letter and contain only alphanumeric characters."
  end
  DBPassword do
    Default "password"
    NoEcho "true"
    Description "The Drupal database admin account password"
    Type "String"
    MinLength "8"
    MaxLength "41"
    AllowedPattern "[a-zA-Z0-9]*"
    ConstraintDescription "must contain only alphanumeric characters."
  end
  DBClass do
    Default "db.m1.small"
    Description "Database instance class"
    Type "String"
    AllowedValues "db.m1.small", "db.m1.large", "db.m1.xlarge", "db.m2.xlarge", "db.m2.2xlarge", "db.m2.4xlarge"
    ConstraintDescription "must select a valid database instance type."
  end
  DBAllocatedStorage do
    Default "5"
    Description "The size of the database (Gb)"
    Type "Number"
    MinValue "5"
    MaxValue "1024"
    ConstraintDescription "must be between 5 and 1024Gb."
  end
  MultiAZDatabase do
    Default "true"
    Description "Create a multi-AZ MySQL Amazon RDS database instance"
    Type "String"
    AllowedValues "true", "false"
    ConstraintDescription "must be either true or false."
  end
  WebServerCapacity do
    Default "2"
    Description "The initial number of WebServer instances"
    Type "Number"
    MinValue "1"
    MaxValue "5"
    ConstraintDescription "must be between 1 and 5 EC2 instances."
  end
  SSHLocation do
    Description "The IP address range that can be used to SSH to the EC2 instances"
    Type "String"
    MinLength "9"
    MaxLength "18"
    Default "0.0.0.0/0"
    AllowedPattern "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
    ConstraintDescription "must be a valid IP CIDR range of the form x.x.x.x/x."
  end
end
Mappings do
  AWSInstanceType2Arch(
    {"t1.micro"=>{"Arch"=>"64"},
     "m1.small"=>{"Arch"=>"64"},
     "m1.medium"=>{"Arch"=>"64"},
     "m1.large"=>{"Arch"=>"64"},
     "m1.xlarge"=>{"Arch"=>"64"},
     "m2.xlarge"=>{"Arch"=>"64"},
     "m2.2xlarge"=>{"Arch"=>"64"},
     "m2.4xlarge"=>{"Arch"=>"64"},
     "m3.xlarge"=>{"Arch"=>"64"},
     "m3.2xlarge"=>{"Arch"=>"64"},
     "c1.medium"=>{"Arch"=>"64"},
     "c1.xlarge"=>{"Arch"=>"64"},
     "cc1.4xlarge"=>{"Arch"=>"64HVM"},
     "cc2.8xlarge"=>{"Arch"=>"64HVM"},
     "cg1.4xlarge"=>{"Arch"=>"64HVM"}})
  AWSRegionArch2AMI(
    {"us-east-1"=>
      {"32"=>"ami-a0cd60c9", "64"=>"ami-aecd60c7", "64HVM"=>"ami-a8cd60c1"},
     "us-west-2"=>
      {"32"=>"ami-46da5576", "64"=>"ami-48da5578", "64HVM"=>"NOT_YET_SUPPORTED"},
     "us-west-1"=>
      {"32"=>"ami-7d4c6938", "64"=>"ami-734c6936", "64HVM"=>"NOT_YET_SUPPORTED"},
     "eu-west-1"=>
      {"32"=>"ami-61555115", "64"=>"ami-6d555119", "64HVM"=>"ami-67555113"},
     "ap-southeast-1"=>
      {"32"=>"ami-220b4a70", "64"=>"ami-3c0b4a6e", "64HVM"=>"NOT_YET_SUPPORTED"},
     "ap-southeast-2"=>
      {"32"=>"ami-8f990eb5", "64"=>"ami-95990eaf", "64HVM"=>"NOT_YET_SUPPORTED"},
     "ap-northeast-1"=>
      {"32"=>"ami-2a19aa2b", "64"=>"ami-2819aa29", "64HVM"=>"NOT_YET_SUPPORTED"},
     "sa-east-1"=>
      {"32"=>"ami-f836e8e5", "64"=>"ami-fe36e8e3", "64HVM"=>"NOT_YET_SUPPORTED"}})
end
Resources do
  S3Bucket do
    Type "AWS::S3::Bucket"
    DeletionPolicy "Retain"
  end
  BucketPolicy do
    Type "AWS::S3::BucketPolicy"
    Properties do
      PolicyDocument do
        Version "2008-10-17"
        Id "UploadPolicy"
        Statement [
          _{
            Sid "EnableReadWrite"
            Action "s3:GetObject", "s3:PutObject", "s3:PutObjectACL"
            Effect "Allow"
            Resource do
              Fn__Join [
                "",
                [
                  "arn:aws:s3:::",
                  _{
                    Ref "S3Bucket"
                  },
                  "/*"
                ]
              ]
            end
            Principal do
              AWS do
                Fn__GetAtt "S3User", "Arn"
              end
            end
          }
        ]
      end
      Bucket do
        Ref "S3Bucket"
      end
    end
  end
  S3User do
    Type "AWS::IAM::User"
    Properties do
      Path "/"
      Policies [
        _{
          PolicyName "root"
          PolicyDocument do
            Statement [
              _{
                Effect "Allow"
                Action "s3:*"
                Resource "*"
              }
            ]
          end
        }
      ]
    end
  end
  S3Keys do
    Type "AWS::IAM::AccessKey"
    Properties do
      UserName do
        Ref "S3User"
      end
    end
  end
  ElasticLoadBalancer do
    Type "AWS::ElasticLoadBalancing::LoadBalancer"
    Metadata do
      Comment "Configure the Load Balancer with a simple health check and cookie-based stickiness"
    end
    Properties do
      AvailabilityZones do
        Fn__GetAZs ""
      end
      LBCookieStickinessPolicy [
        _{
          PolicyName "CookieBasedPolicy"
          CookieExpirationPeriod "30"
        }
      ]
      Listeners [
        _{
          LoadBalancerPort "80"
          InstancePort "80"
          Protocol "HTTP"
          PolicyNames ["CookieBasedPolicy"]
        }
      ]
      HealthCheck do
        Target "HTTP:80/"
        HealthyThreshold "2"
        UnhealthyThreshold "5"
        Interval "10"
        Timeout "5"
      end
    end
  end
  WebServerGroup do
    Type "AWS::AutoScaling::AutoScalingGroup"
    Properties do
      AvailabilityZones do
        Fn__GetAZs ""
      end
      LaunchConfigurationName do
        Ref "LaunchConfig"
      end
      MinSize "1"
      MaxSize "5"
      DesiredCapacity do
        Ref "WebServerCapacity"
      end
      LoadBalancerNames [
        _{
          Ref "ElasticLoadBalancer"
        }
      ]
    end
  end
  LaunchConfig do
    Type "AWS::AutoScaling::LaunchConfiguration"
    Metadata do
      AWS__CloudFormation__Init do
        config do
          packages do
            yum(
              {"httpd"=>[],
               "php"=>[],
               "php-mysql"=>[],
               "php-gd"=>[],
               "php-xml"=>[],
               "php-mbstring"=>[],
               "mysql"=>[],
               "gcc"=>[],
               "make"=>[],
               "libstdc++-devel"=>[],
               "gcc-c++"=>[],
               "fuse"=>[],
               "fuse-devel"=>[],
               "libcurl-devel"=>[],
               "libxml2-devel"=>[],
               "openssl-devel"=>[],
               "mailcap"=>[]})
          end
          sources do
            _path "/var/www/html", "http://ftp.drupal.org/files/projects/drupal-7.8.tar.gz"
            _path "/home/ec2-user", "http://ftp.drupal.org/files/projects/drush-7.x-4.5.tar.gz"
            _path "/home/ec2-user/s3fs", "http://s3fs.googlecode.com/files/s3fs-1.61.tar.gz"
          end
          files do
            _path("/etc/passwd-s3fs") do
              content do
                Fn__Join [
                  "",
                  [
                    _{
                      Ref "S3Keys"
                    },
                    ":",
                    _{
                      Fn__GetAtt "S3Keys", "SecretAccessKey"
                    },
                    "\n"
                  ]
                ]
              end
              mode "000400"
              owner "root"
              group "root"
            end
            _path("/home/ec2-user/settings.php") do
              content do
                Fn__Join [
                  "",
                  [
                    "<?php\n",
                    "\n",
                    "$databases = array (\n",
                    "  'default' =>\n",
                    "  array (\n",
                    "    'default' =>\n",
                    "    array (\n",
                    "      'database' => '",
                    _{
                      Ref "DBName"
                    },
                    "',\n",
                    "      'username' => '",
                    _{
                      Ref "DBUsername"
                    },
                    "',\n",
                    "      'password' => '",
                    _{
                      Ref "DBPassword"
                    },
                    "',\n",
                    "      'host' => '",
                    _{
                      Fn__GetAtt "DBInstance", "Endpoint.Address"
                    },
                    "',\n",
                    "      'port' => '",
                    _{
                      Fn__GetAtt "DBInstance", "Endpoint.Port"
                    },
                    "',\n",
                    "      'driver' => 'mysql',\n",
                    "      'prefix' => 'drupal_',\n",
                    "    ),\n",
                    "  ),\n",
                    ");\n",
                    "\n",
                    "$update_free_access = FALSE;\n",
                    "\n",
                    "$drupal_hash_salt = '0c3R8noNALe3shsioQr5hK1dMHdwRfikLoSfqn0_xpA';\n",
                    "\n",
                    "ini_set('session.gc_probability', 1);\n",
                    "ini_set('session.gc_divisor', 100);\n",
                    "ini_set('session.gc_maxlifetime', 200000);\n",
                    "ini_set('session.cookie_lifetime', 2000000);\n"
                  ]
                ]
              end
              mode "000400"
              owner "root"
              group "root"
            end
          end
          services do
            sysvinit do
              httpd do
                enabled "true"
                ensureRunning "true"
              end
              sendmail do
                enabled "false"
                ensureRunning "false"
              end
            end
          end
        end
      end
    end
    Properties do
      ImageId do
        Fn__FindInMap [
          "AWSRegionArch2AMI",
          _{
            Ref "AWS::Region"
          },
          _{
            Fn__FindInMap [
              "AWSInstanceType2Arch",
              _{
                Ref "InstanceType"
              },
              "Arch"
            ]
          }
        ]
      end
      InstanceType do
        Ref "InstanceType"
      end
      SecurityGroups [
        _{
          Ref "WebServerSecurityGroup"
        }
      ]
      KeyName do
        Ref "KeyName"
      end
      UserData do
        Fn__Base64 do
          Fn__Join [
            "",
            [
              "#!/bin/bash -v\n",
              "yum update -y aws-cfn-bootstrap\n",
              "# Helper function\n",
              "function error_exit\n",
              "{\n",
              "  /opt/aws/bin/cfn-signal -e 1 -r \"$1\" '",
              _{
                Ref "WaitHandle"
              },
              "'\n",
              "  exit 1\n",
              "}\n",
              "# Install Apache Web Server, MySQL and Drupal\n",
              "/opt/aws/bin/cfn-init -s ",
              _{
                Ref "AWS::StackId"
              },
              " -r LaunchConfig ",
              "    --region ",
              _{
                Ref "AWS::Region"
              },
              " || error_exit 'Failed to run cfn-init'\n",
              "# Install s3fs\n",
              "cd /home/ec2-user/s3fs/s3fs-1.61\n",
              "./configure --prefix=/usr\n",
              "make\n",
              "make install\n",
              "# Move the website files to the top level\n",
              "mv /var/www/html/drupal-7.8/* /var/www/html\n",
              "mv /var/www/html/drupal-7.8/.htaccess /var/www/html\n",
              "rm -Rf /var/www/html/drupal-7.8\n",
              "# Mount the S3 bucket\n",
              "mv /var/www/html/sites/default/files /var/www/html/sites/default/files_original\n",
              "mkdir -p /var/www/html/sites/default/files\n",
              "s3fs -o allow_other -o use_cache=/tmp ",
              _{
                Ref "S3Bucket"
              },
              " /var/www/html/sites/default/files || error_exit 'Failed to mount the S3 bucket'\n",
              "echo `hostname` >> /var/www/html/sites/default/files/hosts\n",
              "# Make changes to Apache Web Server configuration\n",
              "sed -i 's/AllowOverride None/AllowOverride All/g'  /etc/httpd/conf/httpd.conf\n",
              "service httpd restart\n",
              "# Only execute the site install if we are the first host up - otherwise we'll end up losing all the data\n",
              "read first < /var/www/html/sites/default/files/hosts\n",
              "if [ `hostname` = $first ]\n",
              "then\n",
              "  # Create the site in Drupal\n",
              "  cd /var/www/html\n",
              "  ~ec2-user/drush/drush site-install standard --yes",
              "     --site-name='",
              _{
                Ref "SiteName"
              },
              "' --site-mail=",
              _{
                Ref "SiteEMail"
              },
              "     --account-name=",
              _{
                Ref "SiteAdmin"
              },
              " --account-pass=",
              _{
                Ref "SitePassword"
              },
              "     --db-url=mysql://",
              _{
                Ref "DBUsername"
              },
              ":",
              _{
                Ref "DBPassword"
              },
              "@",
              _{
                Fn__GetAtt "DBInstance", "Endpoint.Address"
              },
              ":",
              _{
                Fn__GetAtt "DBInstance", "Endpoint.Port"
              },
              "/",
              _{
                Ref "DBName"
              },
              "     --db-prefix=drupal_\n",
              "  # use the S3 bucket for shared file storage\n",
              "  cp -R sites/default/files_original/* sites/default/files\n",
              "  cp -R sites/default/files_original/.htaccess sites/default/files\n",
              "else\n",
              "  # Copy settings.php file since everything else is configured\n",
              "  cp /home/ec2-user/settings.php /var/www/html/sites/default\n",
              "fi\n",
              "rm /home/ec2-user/settings.php\n",
              "# All is well so signal success\n",
              "/opt/aws/bin/cfn-signal -e 0 -r \"Drupal setup complete\" '",
              _{
                Ref "WaitHandle"
              },
              "'\n"
            ]
          ]
        end
      end
    end
  end
  WaitHandle do
    Type "AWS::CloudFormation::WaitConditionHandle"
  end
  WaitCondition do
    Type "AWS::CloudFormation::WaitCondition"
    DependsOn "WebServerGroup"
    Properties do
      Handle do
        Ref "WaitHandle"
      end
      Timeout "600"
    end
  end
  DBInstance do
    Type "AWS::RDS::DBInstance"
    Properties do
      DBName do
        Ref "DBName"
      end
      Engine "MySQL"
      MultiAZ do
        Ref "MultiAZDatabase"
      end
      MasterUsername do
        Ref "DBUsername"
      end
      DBInstanceClass do
        Ref "DBClass"
      end
      DBSecurityGroups [
        _{
          Ref "DBSecurityGroup"
        }
      ]
      AllocatedStorage do
        Ref "DBAllocatedStorage"
      end
      MasterUserPassword do
        Ref "DBPassword"
      end
    end
  end
  DBSecurityGroup do
    Type "AWS::RDS::DBSecurityGroup"
    Properties do
      DBSecurityGroupIngress do
        EC2SecurityGroupName do
          Ref "WebServerSecurityGroup"
        end
      end
      GroupDescription "Frontend Access"
    end
  end
  WebServerSecurityGroup do
    Type "AWS::EC2::SecurityGroup"
    Properties do
      GroupDescription "Enable HTTP access via port 80, locked down to requests from the load balancer only and SSH access"
      SecurityGroupIngress [
        _{
          IpProtocol "tcp"
          FromPort "80"
          ToPort "80"
          SourceSecurityGroupOwnerId do
            Fn__GetAtt "ElasticLoadBalancer", "SourceSecurityGroup.OwnerAlias"
          end
          SourceSecurityGroupName do
            Fn__GetAtt "ElasticLoadBalancer", "SourceSecurityGroup.GroupName"
          end
        },
        _{
          IpProtocol "tcp"
          FromPort "22"
          ToPort "22"
          CidrIp do
            Ref "SSHLocation"
          end
        }
      ]
    end
  end
end
Outputs do
  WebsiteURL do
    Value do
      Fn__Join [
        "",
        [
          "http://",
          _{
            Fn__GetAtt "ElasticLoadBalancer", "DNSName"
          }
        ]
      ]
    end
    Description "Drupal Website"
  end
end
    EOS
  end

  it 'should convert json to dsl with key_conf (use drupal_single_instance_template)' do
    template = JSON.parse(drupal_single_instance_template)

    exclude_key = proc do |k|
      k = k.to_s.gsub('::', '__')
      k !~ /\A[_a-z]\w+\Z/i and k !~ %r|\A/\S*\Z|
    end

    key_conv = proc do |k|
      k = k.to_s

      if k =~ %r|\A/\S*\Z|
        proc do |v, nested|
          if nested
            "_path(#{k.inspect}) #{v}"
          else
            "_path #{k.inspect}, #{v}"
          end
        end
      else
        k.gsub('::', '__')
      end
    end

    dsl = Dslh.deval(template, :key_conv => key_conv, :exclude_key => exclude_key)

    expect(dsl).to eq(<<-'EOS')
AWSTemplateFormatVersion "2010-09-09"
Description "AWS CloudFormation Sample Template Drupal_Single_Instance. Drupal is an open source content management platform powering millions of websites and applications. This template installs a singe instance deployment with a local MySQL database for storage. It uses the AWS CloudFormation bootstrap scripts to install packages and files at instance launch time. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template."
Parameters do
  KeyName do
    Description "Name of an existing EC2 KeyPair to enable SSH access to the instances"
    Type "String"
    MinLength "1"
    MaxLength "255"
    AllowedPattern "[\\x20-\\x7E]*"
    ConstraintDescription "can contain only ASCII characters."
  end
  InstanceType do
    Description "WebServer EC2 instance type"
    Type "String"
    Default "m1.small"
    AllowedValues "t1.micro", "m1.small", "m1.medium", "m1.large", "m1.xlarge", "m2.xlarge", "m2.2xlarge", "m2.4xlarge", "m3.xlarge", "m3.2xlarge", "c1.medium", "c1.xlarge", "cc1.4xlarge", "cc2.8xlarge", "cg1.4xlarge"
    ConstraintDescription "must be a valid EC2 instance type."
  end
  SiteName do
    Default "My Site"
    Description "The name of the Drupal Site"
    Type "String"
  end
  SiteEMail do
    Description "EMail for site adminitrator"
    Type "String"
  end
  SiteAdmin do
    Description "The Drupal site admin account username"
    Type "String"
    MinLength "1"
    MaxLength "16"
    AllowedPattern "[a-zA-Z][a-zA-Z0-9]*"
    ConstraintDescription "must begin with a letter and contain only alphanumeric characters."
  end
  SitePassword do
    NoEcho "true"
    Description "The Drupal site admin account password"
    Type "String"
    MinLength "1"
    MaxLength "41"
    AllowedPattern "[a-zA-Z0-9]*"
    ConstraintDescription "must contain only alphanumeric characters."
  end
  DBName do
    Default "drupaldb"
    Description "The Drupal database name"
    Type "String"
    MinLength "1"
    MaxLength "64"
    AllowedPattern "[a-zA-Z][a-zA-Z0-9]*"
    ConstraintDescription "must begin with a letter and contain only alphanumeric characters."
  end
  DBUsername do
    Default "admin"
    NoEcho "true"
    Description "The Drupal database admin account username"
    Type "String"
    MinLength "1"
    MaxLength "16"
    AllowedPattern "[a-zA-Z][a-zA-Z0-9]*"
    ConstraintDescription "must begin with a letter and contain only alphanumeric characters."
  end
  DBPassword do
    Default "admin"
    NoEcho "true"
    Description "The Drupal database admin account password"
    Type "String"
    MinLength "1"
    MaxLength "41"
    AllowedPattern "[a-zA-Z0-9]*"
    ConstraintDescription "must contain only alphanumeric characters."
  end
  DBRootPassword do
    NoEcho "true"
    Description "Root password for MySQL"
    Type "String"
    MinLength "1"
    MaxLength "41"
    AllowedPattern "[a-zA-Z0-9]*"
    ConstraintDescription "must contain only alphanumeric characters."
  end
  SSHLocation do
    Description "The IP address range that can be used to SSH to the EC2 instances"
    Type "String"
    MinLength "9"
    MaxLength "18"
    Default "0.0.0.0/0"
    AllowedPattern "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
    ConstraintDescription "must be a valid IP CIDR range of the form x.x.x.x/x."
  end
end
Mappings do
  AWSInstanceType2Arch(
    {"t1.micro"=>{"Arch"=>"64"},
     "m1.small"=>{"Arch"=>"64"},
     "m1.medium"=>{"Arch"=>"64"},
     "m1.large"=>{"Arch"=>"64"},
     "m1.xlarge"=>{"Arch"=>"64"},
     "m2.xlarge"=>{"Arch"=>"64"},
     "m2.2xlarge"=>{"Arch"=>"64"},
     "m2.4xlarge"=>{"Arch"=>"64"},
     "m3.xlarge"=>{"Arch"=>"64"},
     "m3.2xlarge"=>{"Arch"=>"64"},
     "c1.medium"=>{"Arch"=>"64"},
     "c1.xlarge"=>{"Arch"=>"64"},
     "cc1.4xlarge"=>{"Arch"=>"64HVM"},
     "cc2.8xlarge"=>{"Arch"=>"64HVM"},
     "cg1.4xlarge"=>{"Arch"=>"64HVM"}})
  AWSRegionArch2AMI(
    {"us-east-1"=>
      {"32"=>"ami-a0cd60c9", "64"=>"ami-aecd60c7", "64HVM"=>"ami-a8cd60c1"},
     "us-west-2"=>
      {"32"=>"ami-46da5576", "64"=>"ami-48da5578", "64HVM"=>"NOT_YET_SUPPORTED"},
     "us-west-1"=>
      {"32"=>"ami-7d4c6938", "64"=>"ami-734c6936", "64HVM"=>"NOT_YET_SUPPORTED"},
     "eu-west-1"=>
      {"32"=>"ami-61555115", "64"=>"ami-6d555119", "64HVM"=>"ami-67555113"},
     "ap-southeast-1"=>
      {"32"=>"ami-220b4a70", "64"=>"ami-3c0b4a6e", "64HVM"=>"NOT_YET_SUPPORTED"},
     "ap-southeast-2"=>
      {"32"=>"ami-b3990e89", "64"=>"ami-bd990e87", "64HVM"=>"NOT_YET_SUPPORTED"},
     "ap-northeast-1"=>
      {"32"=>"ami-2a19aa2b", "64"=>"ami-2819aa29", "64HVM"=>"NOT_YET_SUPPORTED"},
     "sa-east-1"=>
      {"32"=>"ami-f836e8e5", "64"=>"ami-fe36e8e3", "64HVM"=>"NOT_YET_SUPPORTED"}})
end
Resources do
  WebServer do
    Type "AWS::EC2::Instance"
    Metadata do
      AWS__CloudFormation__Init do
        config do
          packages do
            yum(
              {"httpd"=>[],
               "php"=>[],
               "php-mysql"=>[],
               "php-gd"=>[],
               "php-xml"=>[],
               "php-mbstring"=>[],
               "mysql"=>[],
               "mysql-server"=>[],
               "mysql-devel"=>[],
               "mysql-libs"=>[]})
          end
          sources do
            _path "/var/www/html", "http://ftp.drupal.org/files/projects/drupal-7.8.tar.gz"
            _path "/home/ec2-user", "http://ftp.drupal.org/files/projects/drush-7.x-4.5.tar.gz"
          end
          files do
            _path("/tmp/setup.mysql") do
              content do
                Fn__Join [
                  "",
                  [
                    "CREATE DATABASE ",
                    _{
                      Ref "DBName"
                    },
                    ";\n",
                    "CREATE USER '",
                    _{
                      Ref "DBUsername"
                    },
                    "'@'localhost' IDENTIFIED BY '",
                    _{
                      Ref "DBPassword"
                    },
                    "';\n",
                    "GRANT ALL ON ",
                    _{
                      Ref "DBName"
                    },
                    ".* TO '",
                    _{
                      Ref "DBUsername"
                    },
                    "'@'localhost';\n",
                    "FLUSH PRIVILEGES;\n"
                  ]
                ]
              end
              mode "000644"
              owner "root"
              group "root"
            end
          end
          services do
            sysvinit do
              httpd do
                enabled "true"
                ensureRunning "true"
              end
              mysqld do
                enabled "true"
                ensureRunning "true"
              end
              sendmail do
                enabled "false"
                ensureRunning "false"
              end
            end
          end
        end
      end
    end
    Properties do
      ImageId do
        Fn__FindInMap [
          "AWSRegionArch2AMI",
          _{
            Ref "AWS::Region"
          },
          _{
            Fn__FindInMap [
              "AWSInstanceType2Arch",
              _{
                Ref "InstanceType"
              },
              "Arch"
            ]
          }
        ]
      end
      InstanceType do
        Ref "InstanceType"
      end
      SecurityGroups [
        _{
          Ref "WebServerSecurityGroup"
        }
      ]
      KeyName do
        Ref "KeyName"
      end
      UserData do
        Fn__Base64 do
          Fn__Join [
            "",
            [
              "#!/bin/bash -v\n",
              "yum update -y aws-cfn-bootstrap\n",
              "# Helper function\n",
              "function error_exit\n",
              "{\n",
              "  /opt/aws/bin/cfn-signal -e 0 -r \"$1\" '",
              _{
                Ref "WaitHandle"
              },
              "'\n",
              "  exit 1\n",
              "}\n",
              "# Install Apache Web Server, MySQL, PHP and Drupal\n",
              "/opt/aws/bin/cfn-init -s ",
              _{
                Ref "AWS::StackId"
              },
              " -r WebServer ",
              "    --region ",
              _{
                Ref "AWS::Region"
              },
              " || error_exit 'Failed to run cfn-init'\n",
              "# Setup MySQL root password and create a user\n",
              "mysqladmin -u root password '",
              _{
                Ref "DBRootPassword"
              },
              "' || error_exit 'Failed to initialize root password'\n",
              "mysql -u root --password='",
              _{
                Ref "DBRootPassword"
              },
              "' < /tmp/setup.mysql || error_exit 'Failed to create database user'\n",
              "# Make changes to Apache Web Server configuration\n",
              "mv /var/www/html/drupal-7.8/* /var/www/html\n",
              "mv /var/www/html/drupal-7.8/.* /var/www/html\n",
              "rmdir /var/www/html/drupal-7.8\n",
              "sed -i 's/AllowOverride None/AllowOverride All/g'  /etc/httpd/conf/httpd.conf\n",
              "service httpd restart\n",
              "# Create the site in Drupal\n",
              "cd /var/www/html\n",
              "~ec2-user/drush/drush site-install standard --yes",
              "     --site-name='",
              _{
                Ref "SiteName"
              },
              "' --site-mail=",
              _{
                Ref "SiteEMail"
              },
              "     --account-name=",
              _{
                Ref "SiteAdmin"
              },
              " --account-pass=",
              _{
                Ref "SitePassword"
              },
              "     --db-url=mysql://",
              _{
                Ref "DBUsername"
              },
              ":",
              _{
                Ref "DBPassword"
              },
              "@localhost/",
              _{
                Ref "DBName"
              },
              "     --db-prefix=drupal_\n",
              "chown apache:apache sites/default/files\n",
              "# All is well so signal success\n",
              "/opt/aws/bin/cfn-signal -e 0 -r \"Drupal setup complete\" '",
              _{
                Ref "WaitHandle"
              },
              "'\n"
            ]
          ]
        end
      end
    end
  end
  WaitHandle do
    Type "AWS::CloudFormation::WaitConditionHandle"
  end
  WaitCondition do
    Type "AWS::CloudFormation::WaitCondition"
    DependsOn "WebServer"
    Properties do
      Handle do
        Ref "WaitHandle"
      end
      Timeout "300"
    end
  end
  WebServerSecurityGroup do
    Type "AWS::EC2::SecurityGroup"
    Properties do
      GroupDescription "Enable HTTP access via port 80 and SSH access"
      SecurityGroupIngress [
        _{
          IpProtocol "tcp"
          FromPort "80"
          ToPort "80"
          CidrIp "0.0.0.0/0"
        },
        _{
          IpProtocol "tcp"
          FromPort "22"
          ToPort "22"
          CidrIp do
            Ref "SSHLocation"
          end
        }
      ]
    end
  end
end
Outputs do
  WebsiteURL do
    Value do
      Fn__Join [
        "",
        [
          "http://",
          _{
            Fn__GetAtt "WebServer", "PublicDnsName"
          }
        ]
      ]
    end
    Description "Drupal Website"
  end
end
    EOS
  end
end
