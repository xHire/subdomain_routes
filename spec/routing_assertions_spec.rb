require 'test/unit/testresult'
require 'spec_helper'

class UsersController < ActionController::Base
end

describe "routing assertions" do
  context "for generation" do
    before(:each) do
      map_subdomain(:admin, :name => nil) do |admin|
        admin.resources :users
      end
    end

    it "accept a :host option" do
      result = testing_routing do
        assert_recognizes({ :controller => "users", :action => "index", :subdomains => [ "admin" ] }, { :path => "/users", :host => "admin.example.com" })
      end
      result.failure_count.should be_zero
      result.error_count.should be_zero
    end
    
    it "blah" do
      result = testing_routing do
        assert_recognizes({ :controller => "users", :action => "index" }, { :path => "/users", :host => "admin.example.com" })
      end
      result.failure_count.should == 1
      result.error_count.should be_zero
    end


    # it "accept a :host option" do
    #   result = Test::Unit::TestResult.new
    #         
    #   TestClass = Class.new(ActionController::TestCase) do
    #     def test_recognize
    #       assert_recognizes({ :path => "/users", :host => "admin.example.com" }, { :path => "/users", :host => "admin.example.com" })
    #     end
    #   end
    #   
    #   TestClass.new(:test_recognize).run(result) {}
    #     
    #   puts result.inspect
    #   result.error_count.should be_zero
    # end
  end
  
  # context "for recognitions" do
  #   it "should have a test"
  # end
end
