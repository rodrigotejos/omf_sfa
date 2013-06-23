require 'rubygems'
gem 'minitest' # ensures you are using the gem, not the built in MT
require 'minitest/autorun'
require 'minitest/pride'

require 'equivalent-xml'
require 'dm-migrations'
require 'omf-sfa/resource'


include OMF::SFA::Resource

def init_dm
  # setup database
  DataMapper::Logger.new($stdout, :info)

  DataMapper.setup(:default, 'sqlite::memory:')
  #DataMapper.setup(:default, 'sqlite:///tmp/am_test.db')
  DataMapper::Model.raise_on_save_failure = true
  DataMapper.finalize

  DataMapper.auto_migrate!
end

def assert_sfa_xml(resource, expected)
  doc = resource.to_sfa_xml()

  expected = format expected, 'xmlns="http://www.protogeni.net/resources/rspec/2" xmlns:omf="http://schema.mytestbed.net/sfa/rspec/1"'
  exp = Nokogiri.XML(expected)
  EquivalentXml.equivalent?(doc, exp)
  #doc.must_be equivalent_to(exp)
end


describe Node do
  before do
    init_dm
  end

  it 'can create a node' do
    Node.create()
  end

  it 'can serialize a simple node' do
    n = Node.create(:name => 'n1')
    assert_sfa_xml n, %{
      <node %s
          id="#{n.uuid}"
          omf:href="/resources/#{n.uuid}"
          component_id="urn:publicid:IDN+mytestbed.net+node+#{n.uuid}"
          component_manager_id="authority+am"
          component_name="n1">
        <available now="true"/>
      </node>
    }
  end

  it 'can have an interface' do
    n = Node.create(:name => 'n1')
    n.interfaces << (if1 = Interface.create(:name => 'if1'))

    assert_sfa_xml n, %{
      <node %s
          id="#{n.uuid}"
          omf:href="/resources/#{n.uuid}"
          component_id="urn:publicid:IDN+mytestbed.net+node+#{n.uuid}"
          component_manager_id="authority+am"
          component_name="n1">
        <available now="true"/>
        <interface
            id="#{if1.uuid}"
            omf:href="/resources/#{if1.uuid}"
            component_id="urn:publicid:IDN+mytestbed.net+interface+#{if1.uuid}"
            component_manager_id="authority+am"
            component_name="if1"
        />
      </node>
    }
  end

  it 'can have multiples interface' do
    n = Node.create(:name => 'n1')
    n.interfaces << (if1 = Interface.create(:name => 'if1'))
    n.interfaces << (if2 = Interface.create(:name => 'if2'))

    n.to_sfa_hash().must_be_same_as ({
      "href" => "/resources/#{n.uuid}", "uuid" => n.uuid.to_s, "sfa_class" => "node",
      "component_name" => "n1", "component_manager_id" => "authority+am",
      "component_id" => "urn:publicid:IDN+mytestbed.net+node+#{n.uuid}",
      "available" => "true",
      "interfaces" => [{
        "href" => "/resources/#{if1.uuid}",
        "uuid" => if1.uuid.to_s,
        "sfa_class" => "interface",
        "component_name" => "if1",
        "component_manager_id" => "authority+am",
        "component_id" => "urn:publicid:IDN+mytestbed.net+interface+#{if1.uuid}",
      }, {
        "href" => "/resources/#{if2.uuid}",
        "uuid" => if2.uuid.to_s,
        "sfa_class" => "interface",
        "component_name" => "if2",
        "component_manager_id" => "authority+am",
        "component_id" => "urn:publicid:IDN+mytestbed.net+interface+#{if2.uuid}",
      }]
    })

    assert_sfa_xml n, %{
      <node %s
          id="#{n.uuid}"
          omf:href="/resources/#{n.uuid}"
          component_id="urn:publicid:IDN+mytestbed.net+node+#{n.uuid}"
          component_manager_id="authority+am"
          component_name="n1">
        <available now="true"/>
        <interface
            id="#{if1.uuid}"
            omf:href="/resources/#{if1.uuid}"
            component_id="urn:publicid:IDN+mytestbed.net+interface+#{if1.uuid}"
            component_manager_id="authority+am"
            component_name="if1"
        />
        <interface
            id="#{if2.uuid}"
            omf:href="/resources/#{if2.uuid}"
            component_id="urn:publicid:IDN+mytestbed.net+interface+#{if2.uuid}"
            component_manager_id="authority+am"
            component_name="if2"
        />
      </node>
    }
    # doc = Nokogiri::XML::Document.new
    # n.to_sfa_xml(doc)
#
    # exp = Nokogiri.XML(%{
            # <node
                # id="#{n.sfa_id}"
                # component_id="urn:publicid:IDN+mytestbed.net+node+n1"
                # component_manager_id="authority+am"
                # component_name="n1">
              # <available now="true"/>
              # <interface_ref component_id="urn:publicid:IDN+mytestbed.net+interface+if1"/>
              # <interface_ref component_id="urn:publicid:IDN+mytestbed.net+interface+if2"/>
            # </node>})
    # doc.should be_equivalent_to(exp)
  end

  it 'can have multiples identical interface' do
    n = Node.create(:name => 'n1')
    n.interfaces << (if1 = Interface.create(:name => 'if1'))
    n.interfaces << if1

    n.to_sfa_hash().must_be_same_as ({
      "href" => "/resources/#{n.uuid}", "uuid" => n.uuid.to_s, "sfa_class" => "node",
      "component_name" => "n1", "component_manager_id" => "authority+am",
      "component_id" => "urn:publicid:IDN+mytestbed.net+node+#{n.uuid}",
      "available" => "true",
      "interfaces" => [{
        "href" => "/resources/#{if1.uuid}",
        "uuid" => if1.uuid.to_s,
        "sfa_class" => "interface",
        "component_name" => "if1",
        "component_manager_id" => "authority+am",
        "component_id" => "urn:publicid:IDN+mytestbed.net+interface+#{if1.uuid}",
      }, {
        "component_name" => "if1",
        "href" => "/resources/#{if1.uuid}",
        "uuid" => if1.uuid.to_s
      }]
    })

    assert_sfa_xml n, %{
      <node %s
          id="#{n.uuid}"
          omf:href="/resources/#{n.uuid}"
          component_id="urn:publicid:IDN+mytestbed.net+node+#{n.uuid}"
          component_manager_id="authority+am"
          component_name="n1">
        <available now="true"/>
        <interface
            id="#{if1.uuid}"
            omf:href="/resources/#{if1.uuid}"
            component_id="urn:publicid:IDN+mytestbed.net+interface+#{if1.uuid}"
            component_manager_id="authority+am"
            component_name="if1"
        />
        <interface_ref
            id_ref="#{if1.uuid}"
            component_id="urn:publicid:IDN+mytestbed.net+interface+#{if1.uuid}"
        />
      </node>
    }

  end
end
