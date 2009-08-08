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

  context "for assert_recognizes" do
    it "should correctly succeed with a :host option and a subdomain route" do
      result = testing_routing do
        assert_recognizes(@options, { :path => "/users", :host => "admin.example.com" })
      end
      result.error_count.should be_zero
      result.failure_count.should be_zero
    end
    
    it "should correctly fail with a :host option and a subdomain route" do
      result = testing_routing do
        assert_recognizes(@options, { :path => "/users", :host => "www.example.com" } )
      end
      result.error_count.should == 1
    end
  end

  context "for assert_generates" do
    it "should correctly succeed with :host and :path options and a subdomain route which changes the subdomain" do
      result = testing_routing do
        assert_generates({ :path => "http://admin.example.com/users", :host => "www.example.com" }, @options)
      end
      result.assertion_count.should > 0
      result.error_count.should be_zero
      puts result.inspect
      result.failure_count.should be_zero
    end
  
    it "should correctly fail with :host and :path options and a subdomain route which changes the subdomain" do
      result = testing_routing do
        assert_generates({ :path => "http://admin.example.com/users", :host => "admin.example.com" }, @options)
      end
      result.assertion_count.should > 0
      result.error_count.should be_zero
      result.failure_count.should == 1
    end

    it "should correctly succeed with :host and :path options and a subdomain route which doesn't change the subdomain" do
      result = testing_routing do
        assert_generates({ :path => "/users", :host => "admin.example.com" }, @options)
      end
      result.assertion_count.should > 0
      result.error_count.should be_zero
      result.failure_count.should be_zero
    end

    it "should correctly fail with :host and :path options and a subdomain route which doesn't change the subdomain" do
      result = testing_routing do
        assert_generates({ :path => "/users", :host => "www.example.com" }, @options)
      end
      result.assertion_count.should > 0
      result.error_count.should be_zero
      result.failure_count.should == 1
    end
  end  
end
