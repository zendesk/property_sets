# Property sets [![Build Status](https://travis-ci.org/zendesk/property_sets.png)](https://travis-ci.org/zendesk/property_sets)

This gem is a way for you to use a basic "key/value" store for storing attributes for a given model in a relational fashion where there's a row per attribute. Alternatively you'd need to add a new column per attribute to your main table, or serialize the attributes and their values using the [ActiveRecord 3.2 store](https://github.com/rails/rails/commit/85b64f98d100d37b3a232c315daa10fad37dccdc).

## Description

You configure the allowed stored properties by specifying these in the model:

```ruby
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
```

The declared properties can then be accessed runtime via the defined association:

```ruby
# Return the value of the version record for this account, or the default value if not set
account.settings.version

# Update the version record with given value
account.settings.version = "v1.1"

# Query the truth value of the property
account.settings.featured?

# Short hand for setting one or more values
account.settings.set(:version => "v1.2", :activated => true)

# Short hand for getting a hash with pairs for each key argument
account.settings.get([:version, :activated])
```

### Validations

Property sets supports standard AR validations, although in a somewhat manual fashion.

```ruby
class Account < ActiveRecord::Base
  property_set :settings do
    property :version, :default => "v1.0"
    property :featured, :protected => true

    validates_format_of :value, :with => /v\d+\.\d+/, :message => "of version is invalid",
                        :if => Proc.new { |r| r.name.to_sym == :version }
  end
end
```

On `account.save` this will result in an error record being added. You can also inspect the
setting record using `account.settings.version_record`

### Bulk operations

Stored properties can also be updated with the update_attributes and update_attributes! methods by
enabling nested attributes. Like this (from the test cases):

```ruby
@account.texts_attributes = [
  { :name => "foo", :value => "1"  },
  { :name => "bar", :value => "0"  }
]
```

And for existing records:

```ruby
@account.update_attributes!(:texts_attributes => [
  { :id => @account.texts.foo.id, :name => "foo", :value => "0"  },
  { :id => @account.texts.bar.id, :name => "bar", :value => "1" }
])
```

Using nested attributes is subject to implementing your own security measures for mass update assignments.
Alternatively, it is possible to use a custom hash structure:

```ruby
params = {
  :settings => { :version => "v4.0", :featured => "1" },
  :texts    => { :epilogue => "Wibble wobble" }
}

@account.update_attributes(params)
```

The above will not update `featured` as this has the protected flag set and is hence protected from
mass updates.

### View helpers

We support a couple of convenience mechanisms for building forms and putting the values into the above hash structure. So far, only support check boxes and radio buttons:

```erb
<% form_for(:account, :html => { :method => :put }) do |f| %>
  <h3><%= f.property_set(:settings).check_box :activated %> Activated?</h3>
  <h3><%= f.property_set(:settings).radio_button :hot, "yes" %> Hot</h3>
  <h3><%= f.property_set(:settings).radio_button :not, "no" %> Not</h3>
  <h3><%= f.property_set(:settings).select :level, [["One", 1], ["Two", 2]] %></h3>
<% end %>
```

## Installation

Install the gem in your rails project by putting it in your Gemfile:

```
gem "property_sets"
```

Also remember to create the storage table(s), if for example you are going to be using this with an accounts model and a "settings" property set, you can define the table like:

```ruby
create_table :account_settings do |t|
  t.integer :account_id, :null => false
  t.string  :name, :null => false
  t.string  :value
  t.timestamps
end

add_index :account_settings, [ :account_id, :name ], :unique => true
```

If you would like to serialize larger objects into your property sets, you can use a `TEXT` column type for value like this:

```ruby
create_table :account_settings do |t|
  t.integer :account_id, :null => false
  t.string  :name, :null => false
  t.text    :value
  t.timestamps
end

add_index :account_settings, [ :account_id, :name ], :unique => true
```

## Requirements

* ActiveRecord
* ActiveSupport

## License and copyright

Copyright 2013 Zendesk

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
