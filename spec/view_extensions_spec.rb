require "spec_helper"

describe "property set view extensions" do
  def base_options
    {
      name: "#{object_name}[#{property_set}][#{property}]",
      id: "#{object_name}_#{property_set}_#{property}",
      object: object
    }
  end

  let(:property_set) { :settings }
  let(:property) { :active }
  let(:object_name) { "object_name" }
  let(:object) { double("View object") }
  let(:template) { double("Template") }
  let(:builder) { ActionView::Helpers::FormBuilder.new(object_name, object, template, {}) }
  let(:proxy) { builder.property_set(property_set) }

  it "provide a form builder proxy" do
    expect(proxy).to be_a(ActionView::Helpers::FormBuilder::PropertySetFormBuilderProxy)
    expect(proxy.property_set).to eq(property_set)
  end

  describe "object is not available" do
    let(:builder) { ActionView::Helpers::FormBuilder.new(object_name, nil, template, {}) }

    it "fetch the target object when not available" do
      allow(object).to receive(property_set).and_return(double("Fake property", property => "value"))
      allow(template).to receive(:hidden_field)

      expect(template).to receive(:instance_variable_get).with(:"@#{object_name}").and_return(object)
      proxy.hidden_field(property)
    end
  end

  describe "#check_box" do
    describe "when called with checked true for a truth value" do
      before do
        settings = double("Fake setting", property => "1", :"#{property}?" => true)
        allow(object).to receive(property_set).and_return(settings)
      end

      it "build a checkbox with the proper parameters" do
        expected_options = base_options.merge(checked: true)
        expect(template).to receive(:check_box).with(object_name, property, expected_options, "1", "0")
        proxy.check_box(property)
      end
    end

    describe "when called with checked false for a truth value" do
      before do
        settings = double("Fake setting", property => "0", :"#{property}?" => false)
        allow(object).to receive(property_set).and_return(settings)
      end

      it "build a checkbox with the proper parameters" do
        expected_options = base_options.merge(checked: false)
        expect(template).to receive(:check_box).with(object_name, property, expected_options, "1", "0")
        proxy.check_box(property)
      end
    end
  end

  describe "#hidden_field" do
    describe "when the persisted value is not a boolean" do
      before do
        settings = double("Fake property", property => "persisted value")
        allow(object).to receive(property_set).and_return(settings)
      end

      it "build a hidden field with the persisted value" do
        expected_options = base_options.merge(value: "persisted value")
        expect(template).to receive(:hidden_field).with(object_name, property, expected_options)
        proxy.hidden_field(property)
      end

      describe "and a value is provided" do
        it "build a hidden field with the provided value" do
          expected_options = base_options.merge(value: "provided value")
          expect(template).to receive(:hidden_field).with(object_name, property, expected_options)
          proxy.hidden_field(property, {value: "provided value"})
        end
      end
    end

    describe "when the persisted value is a boolean" do
      it "build a hidden field with cast boolean value if it is a boolean true" do
        settings = double("Fake property", property => true)
        allow(object).to receive(property_set).and_return(settings)

        expected_options = base_options.merge(value: "1")
        expect(template).to receive(:hidden_field).with(object_name, property, expected_options)
        proxy.hidden_field(property)
      end

      it "build a hidden field with cast boolean value if it is a boolean false" do
        settings = double("Fake property", property => false)
        allow(object).to receive(property_set).and_return(settings)

        expected_options = base_options.merge(value: "0")
        expect(template).to receive(:hidden_field).with(object_name, property, expected_options)
        proxy.hidden_field(property)
      end
    end
  end

  describe "#text_field" do
    describe "when called with a provided value" do
      before do
        settings = double("Fake property", property => "persisted value")
        allow(object).to receive(property_set).and_return(settings)
      end

      it "build a text field with the provided value" do
        expected_options = base_options.merge(value: "provided value")
        expect(template).to receive(:text_field).with(object_name, property, expected_options)
        proxy.text_field(property, {value: "provided value"})
      end
    end
  end

  describe "#radio_button" do
    let(:expected_options) {
      base_options.merge(
        id: "#{object_name}_#{property_set}_#{property}_hello",
        checked: false
      )
    }

    let(:faked_property) { double("Fake property", property => "hello") }

    before do
      allow(object).to receive(property_set).and_return(faked_property)
    end

    it "generate a unique id when one is not provided" do
      expected_options[:id] = "#{object_name}_#{property_set}_#{property}_pancake"
      expect(template).to receive(:radio_button).with(object_name, property, "pancake", expected_options)
      proxy.radio_button(property, "pancake")
    end

    describe "when called with checked true for a truth value" do
      it "call with checked true for a truth value" do
        expected_options[:checked] = true
        expect(template).to receive(:radio_button).with(object_name, property, "hello", expected_options)
        proxy.radio_button(property, "hello")
      end
    end

    describe "when called with a value of a different type" do
      let(:faked_property) { double("Fake property", property => "1") }

      it "call with checked false" do
        expected_options[:id] = "#{object_name}_#{property_set}_#{property}_1"
        expect(template).to receive(:radio_button).with(object_name, property, 1, expected_options)
        proxy.radio_button(property, 1)
      end
    end
  end

  describe "#select" do
    before do
      settings = double("Fake property", count: "2")
      allow(object).to receive(property_set).and_return(settings)
    end

    it "render a <select> with <option>s" do
      select_options = {selected: "2"}
      select_choices = [["One", 1], ["Two", 2], ["Three", 3]]

      expect(template).to receive(:select).with("object_name[settings]", :count, select_choices, select_options, {})
      proxy.select(:count, select_choices)
    end

    it "merge :html_options" do
      select_options = {selected: "2"}
      select_choices = [["One", 1], ["Two", 2], ["Three", 3]]
      html_options = {id: "foo", name: "bar", disabled: true}

      expect(template).to receive(:select).with("object_name[settings]", :count, select_choices, select_options, html_options)
      proxy.select(:count, select_choices, select_options, html_options)
    end
  end
end
