# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.10.0] - 2023-11-08

* Property tables can now live on a separate database to their parent models. This is achieved, on a per-model basis, by configuring the connection class that will be used by property sets. e.g. set `self.property_sets_connection_class = Foo` on the model to instruct `property_sets` to use `Foo`'s database connection when looking for the property sets tables.

## [3.10.0] - 2023-09-18

* Property models now inherit from the same parent as their owners (this unblocks [using multiple databases natively in Rails](https://guides.rubyonrails.org/active_record_multiple_databases.html)).
* Dropped support for Rails 5.
