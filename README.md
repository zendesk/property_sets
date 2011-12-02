# Property sets [![Build Status](https://secure.travis-ci.org/morten/property_sets.png)](http://travis-ci.org/morten/property_sets)

This gem is a way for you to use a basic "key/value" store for storing attributes for a given model in a relational fashion where there's a row per attribute. Alternatively you'd need to add a new column per attribute to your main table, or serialize the attributes and their values.

## Description

You configure the allowed stored properties by specifying these in the model:

    class Account < ActiveRecord::Base
      property_set :settings do
        property :version, :default => "v1.0"
        property :featured, :protected => true
        property :activated
      end

      property_set :texts do
        property :epilogue
      end
    end

The declared properties can then be accessed runtime via the defined association:

    # Return the value of the version record for this account, or the default value if not set
    account.settings.version

    # Update the version record with given value
    account.settings.version = "v1.1"

    # Query the truth value of the property
    account.settings.featured?

    # Short hand for setting one or more values
    account.settings.set(:version => "v1.2", :activated => true)

### Validations

Property sets supports standard AR validations, although in a somewhat manual fashion.

    class Account < ActiveRecord::Base
      property_set :settings do
        property :version, :default => "v1.0"
        property :featured, :protected => true
    
        validates_format_of :value, :with => /v\d+\.\d+/, :message => "of version is invalid",
                            :if => Proc.new { |r| r.name.to_sym == :version }
      end
    end

On +account.save+ this will result in an error record being added. You can also inspect the
setting record using +account.settings.version_record+

### Bulk operations

Stored properties can also be updated with the update_attributes and update_attributes! methods by
enabling nested attributes. Like this (from the test cases):

    @account.texts_attributes = [
      { :name => "foo", :value => "1"  },
      { :name => "bar", :value => "0"  }
    ]

And for existing records:

    @account.update_attributes!(:texts_attributes => [
      { :id => @account.texts.foo.id, :name => "foo", :value => "0"  },
      { :id => @account.texts.bar.id, :name => "bar", :value => "1" }
    ])

Using nested attributes is subject to implementing your own security measures for mass update assignments.
Alternatively, it is possible to use a custom hash structure:

    params = {
      :settings => { :version => "v4.0", :featured => "1" },
      :texts    => { :epilogue => "Wibble wobble" }
    }
    @account.update_attributes(params)

The above will not update +featured+ as this has the protected flag set and is hence protected from
mass updates.

### View helpers

We support a couple of convenience mechanisms for building forms and putting the values into the above hash structure. So far, only support check boxes and radio buttons:

    <% form_for(:account, :html => { :method => :put }) do |f| %>
      <h3><%= f.property_set(:settings).check_box :activated %> Activated?</h3>
      <h3><%= f.property_set(:settings).radio_button :hot, "yes" %> Hot</h3>
      <h3><%= f.property_set(:settings).radio_button :not, "no" %> Not</h3>
      <h3><%= f.property_set(:settings).select :level, [["One", 1], ["Two", 2]] %></h3>
    <% end %>

## Installation

Install the gem in your rails project by putting it in your Gemfile:

    gem "property_sets"

Also remember to create the storage table(s), if for example you are going to be using this with an accounts model and a "settings" property set, you can define the table like:

    create_table :account_settings do |t|
      t.integer  :account_id, :null => false
      t.string   :name, :null => false
      t.string   :value
      t.timestamps
    end
    
    add_index :account_settings, [ :account_id, :name ], :unique => true

## Requirements

* ActiveRecord
* ActiveSupport

