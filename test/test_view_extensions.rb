require File.expand_path('../helper', __FILE__)

describe "property set view extensions" do
  def base_options
    {
      :name   => "#{@object_name}[#{@property_set}][#{@property}]",
      :id     => "#{@object_name}_#{@property_set}_#{@property}",
      :object => @object
    }
  end

  before do
    @property_set = :settings
    @property     = :active
    @object_name  = 'object_name'
    @object       = stub
    @template     = stub
    @builder      = ActionView::Helpers::FormBuilder.new(@object_name, @object, @template, {})
    @proxy        = @builder.property_set(@property_set)
  end

  it "provide a form builder proxy" do
    assert @proxy.is_a?(ActionView::Helpers::FormBuilder::PropertySetFormBuilderProxy)
    assert_equal @property_set, @proxy.property_set
  end

  it "fetch the target object when not available" do
    @builder = ActionView::Helpers::FormBuilder.new(@object_name, nil, @template, {})
    @proxy   = @builder.property_set(@property_set)

    @object.stubs(@property_set).returns(stub(@property => 'value'))
    @template.stubs(:hidden_field)

    @template.expects(:instance_variable_get).with("@#{@object_name}").returns(@object)
    @proxy.hidden_field(@property)
  end

  describe "#check_box" do
    describe "when called with checked true for a truth value" do
      before do
        settings = stub(@property => '1', "#{@property}?".to_sym => true)
        @object.stubs(@property_set).returns(settings)
      end

      it "build a checkbox with the proper parameters" do
        expected_options = base_options.merge(:checked => true)
        @template.expects(:check_box).with(@object_name, @property, expected_options, '1', '0')
        @proxy.check_box(@property)
      end
    end

    describe "when called with checked false for a truth value" do
      before do
        settings = stub(@property => '0', "#{@property}?".to_sym => false)
        @object.stubs(@property_set).returns(settings)
      end

      it "build a checkbox with the proper parameters" do
        expected_options = base_options.merge(:checked => false)
        @template.expects(:check_box).with(@object_name, @property, expected_options, '1', '0')
        @proxy.check_box(@property)
      end
    end
  end

  describe "#hidden_field" do
    describe "when the persisted value is not a boolean" do
      before do
        settings = stub(@property => 'persisted value')
        @object.stubs(@property_set).returns(settings)
      end

      it "build a hidden field with the persisted value" do
        expected_options = base_options.merge(:value => 'persisted value')
        @template.expects(:hidden_field).with(@object_name, @property, expected_options)
        @proxy.hidden_field(@property)
      end

      describe "and a value is provided" do
        it "build a hidden field with the provided value" do
          expected_options = base_options.merge(:value => 'provided value')
          @template.expects(:hidden_field).with(@object_name, @property, expected_options)
          @proxy.hidden_field(@property, {:value => 'provided value'})
        end
      end
    end

    describe "when the persisted value is a boolean" do
      it "build a hidden field with cast boolean value if it is a boolean true" do
        settings = stub(@property => true)
        @object.stubs(@property_set).returns(settings)

        expected_options = base_options.merge(:value => '1')
        @template.expects(:hidden_field).with(@object_name, @property, expected_options)
        @proxy.hidden_field(@property)
      end

      it "build a hidden field with cast boolean value if it is a boolean false" do
        settings = stub(@property => false)
        @object.stubs(@property_set).returns(settings)

        expected_options = base_options.merge(:value => '0')
        @template.expects(:hidden_field).with(@object_name, @property, expected_options)
        @proxy.hidden_field(@property)
      end
    end
  end

  describe "#text_field" do
    describe "when called with a provided value" do
      before do
        settings = stub(@property => 'persisted value')
        @object.stubs(@property_set).returns(settings)
      end

      it "build a text field with the provided value" do
        expected_options = base_options.merge(:value => 'provided value')
        @template.expects(:text_field).with(@object_name, @property, expected_options)
        @proxy.text_field(@property, {:value => 'provided value'})
      end
    end
  end

  describe "#radio_button" do
    before do
      settings = stub(@property => 'hello')
      @object.stubs(@property_set).returns(settings)

      @expected_options = base_options.merge(
        :id      => "#{@object_name}_#{@property_set}_#{@property}_hello",
        :checked => false
      )
    end

    it "generate a unique id when one is not provided" do
        @expected_options.merge!(
          :id => "#{@object_name}_#{@property_set}_#{@property}_pancake"
        )
        @template.expects(:radio_button).with(@object_name, @property, 'pancake', @expected_options)
        @proxy.radio_button(@property, 'pancake')
    end

    describe "when called with checked true for a truth value" do

      it "call with checked true for a truth value" do
        @expected_options.merge!(:checked => true)
        @template.expects(:radio_button).with(@object_name, @property, 'hello', @expected_options)
        @proxy.radio_button(@property, 'hello')
      end
    end

    describe "when called with a value of a different type" do
      before do
        settings = stub(@property => '1')
        @object.stubs(@property_set).returns(settings)
      end

      it "call with checked false" do
        @expected_options.merge!(
          :id => "#{@object_name}_#{@property_set}_#{@property}_1"
        )
        @template.expects(:radio_button).with(@object_name, @property, 1, @expected_options)
        @proxy.radio_button(@property, 1)
      end
    end
  end

  describe "#select" do
    before do
      settings = stub(:count => '2')
      @object.stubs(@property_set).returns(settings)
    end

    it "render a <select> with <option>s" do
      select_options = { :selected => "2" }
      select_choices = [["One", 1], ["Two", 2], ["Three", 3]]

      @template.expects(:select).with("object_name[settings]", :count, select_choices, select_options, {})
      @proxy.select(:count, select_choices)
    end

    it "merge :html_options" do
      select_options = { :selected => "2" }
      select_choices = [["One", 1], ["Two", 2], ["Three", 3]]
      html_options   = { :id => "foo", :name => "bar", :disabled => true }

      @template.expects(:select).with("object_name[settings]", :count, select_choices, select_options, html_options)
      @proxy.select(:count, select_choices, select_options, html_options)
    end
  end
end
