#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rake/testtask'

task :default => :test

desc "Run tests"
task :test do
  Rake::TestTask.new do |t|
    t.libs << 'lib'
    t.pattern = 'test/**/*_test.rb'
    t.verbose = false
  end
end
