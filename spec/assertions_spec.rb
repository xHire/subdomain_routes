require 'test/unit/testresult'
require 'spec_helper'

class UsersController < ActionController::Base
end

describe "routing assertions" do
  before(:each) do
    map_subdomain(:admin, :name => nil) do |admin|
      admin.resources :users
    end
    @options = { :controller => "users", :action => "index", :subdomains => [ "admin" ] }
  end

  context "for recognition" do
    it "should correctly succeed with a :host option and a subdomain route" do
      test = lambda { assert_recognizes_with_host(@options, { :path => "/users", :host => "admin.example.com" }) }
      test.should_not have_errors
      test.should_not fail
    end
    
    it "should correctly fail with a :host option and a subdomain route" do
      test = lambda { assert_recognizes_with_host(@options, { :path => "/users", :host => "www.example.com" } ) }
      test.should have_errors
    end
  end

  context "for generation" do
    it "should correctly succeed with :host and :path options and a subdomain route which changes the subdomain" do
      test = lambda { assert_generates_with_host("http://admin.example.com/users", "www.example.com", @options) }
      test.should_not have_errors
      test.should_not fail
    end
  
    it "should correctly fail with :host and :path options and a subdomain route which changes the subdomain" do
      test = lambda { assert_generates_with_host("http://admin.example.com/users", "admin.example.com", @options) }
      test.should_not have_errors
      test.should fail
    end
      
    it "should correctly succeed with :host and :path options and a subdomain route which doesn't change the subdomain" do
      test = lambda { assert_generates_with_host("/users", "admin.example.com", @options) }
      test.should_not have_errors
      test.should_not fail
    end
    
    it "should correctly fail with :host and :path options and a subdomain route which doesn't change the subdomain" do
      test = lambda { assert_generates_with_host("/users", "www.example.com", @options) }
      test.should_not have_errors
      test.should fail
    end
  end
end
