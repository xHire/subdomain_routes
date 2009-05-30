require 'spec_helper'

describe "URL writing" do
  before(:each) do
    ActionController::Routing::Routes.clear!
    SubdomainRoutes::Config.stub!(:domain_length).and_return(2)
  end
  
  { "nil" => nil, "an IP address" => "207.192.69.152" }.each do |host_type, host|
    context "when the host is #{host_type}" do
      it "should raise an error when a subdomain route is requested" do
        map_subdomain(:www) { |www| www.resources :users }
        with_host(host) { lambda { www_users_path }.should raise_error(SubdomainRoutes::HostNotSupplied) }
      end
      
      context "and a non-subdomain route is requested" do
        before(:each) do
          ActionController::Routing::Routes.draw { |map| map.resources :users }
        end

        it "should not raise an error when the route is a path" do
          with_host(host) do
            lambda { users_path }.should_not raise_error
          end
        end
      end
    end
  end

  [ [ "single", :admin, "admin.example.com" ],
    [    "nil",    nil,       "example.com" ] ].each do |type, subdomain, host|
    context "when a #{type} subdomain is specified" do
      before(:each) do
        map_subdomain(subdomain, :name => nil) { |map| map.resources :users }
      end
  
      it "should not change the host for an URL if the host subdomain matches" do
        with_host(host) do
          users_url.should == "http://#{host}/users"
        end
      end
    
      it "should change the host for an URL if the host subdomain differs" do
        with_host "other.example.com" do
          users_url.should == "http://#{host}/users"
        end
      end

      it "should not force the host for a path if the host subdomain matches" do
        with_host(host) do
          users_path.should == "/users"
        end
      end

      it "should force the host for a path if the host subdomain differs" do
        with_host "other.example.com" do
          users_path.should == "http://#{host}/users"
        end
      end
  
      context "and a subdomain different from the host subdomain is explicitly requested" do
        it "should change the host if the requested subdomain matches" do
          with_host "other.example.com" do
            users_path(:subdomain => subdomain).should == "http://#{host}/users"
          end
        end
    
        it "should raise a routing error if the requested subdomain doesn't match" do
          with_host(host) do
            lambda { users_path(:subdomain => :other) }.should raise_error(ActionController::RoutingError)
          end
        end
      end
      
      context "and the current host's subdomain is explicitly requested" do
        it "should not force the host for a path if the subdomain matches" do
          with_host(host) do
            users_path(:subdomain => subdomain).should == "/users"
          end
        end
      end
    end
  end
  
  [ [               "", [ :books, :dvds ], [ "books.example.com", "dvds.example.com" ] ],
    [ " including nil",     [ nil, :www ], [       "example.com",  "www.example.com" ] ] ].each do |qualifier, subdomains, hosts|
    context "when multiple subdomains#{qualifier} are specified" do
      before(:each) do
        args = subdomains + [ :name => nil ]
        map_subdomain(*args) { |map| map.resources :items }
      end
          
      it "should not change the host for an URL if the host subdomain matches" do
        hosts.each do |host|
          with_host(host) do
            items_url.should == "http://#{host}/items"
          end
        end
      end
  
      it "should not force the host for a path if the host subdomain matches" do
        hosts.each do |host|
          with_host(host) do
            items_path.should == "/items"
          end
        end
      end
  
      it "should raise a routing error if the host subdomain doesn't match" do
        with_host "other.example.com" do
          lambda {  item_url }.should raise_error(ActionController::RoutingError)
          lambda { item_path }.should raise_error(ActionController::RoutingError)
        end
      end
    
      context "and a subdomain different from the host subdomain is explicitly requested" do
        it "should change the host if the requested subdomain matches" do
          [ [ subdomains.first, hosts.first, hosts.last ],
            [ subdomains.last, hosts.last, hosts.first ] ].each do |subdomain, new_host, old_host|
            with_host(old_host) do
              items_path(:subdomain => subdomain).should == "http://#{new_host}/items"
            end
          end
        end
          
        it "should raise a routing error if the requested subdomain doesn't match" do
          [ [ hosts.first, hosts.last ],
            [ hosts.last, hosts.first ] ].each do |new_host, old_host|
            with_host(old_host) do
              lambda { items_path(:subdomain => :other) }.should raise_error(ActionController::RoutingError)
            end
          end
        end
      end
    end
  end
  
  it "should downcase a supplied subdomain" do
    map_subdomain(:www1, :www2, :name => nil) { |map| map.resources :users }
    [ [ :Www1, "www1" ], [ "Www2", "www2" ] ].each do |mixedcase, lowercase|
      with_host "www.example.com" do
        users_url(:subdomain => mixedcase).should == "http://#{lowercase}.example.com/users"
      end
    end
  end
  
  context "when a :proc subdomain is specified" do          
    before(:each) do
      map_subdomain(:proc => :city) { |city| city.resources :events }
    end
    
    it "should raise a routing error without a recognize proc" do
      with_host "boston.example.com" do
        lambda {  city_events_url }.should raise_error(ActionController::RoutingError)
        lambda { city_events_path }.should raise_error(ActionController::RoutingError)
      end
    end
    
    context "and a recognize proc is defined" do
      before(:each) do
        ActionController::Routing::Routes.recognize_subdomain(:city) { |city| } # this block will be stubbed
      end
      
      it "should not change the host if the recognize proc returns true" do
        with_host "boston.example.com" do
          ActionController::Routing::Routes.subdomain_procs.should_receive(:recognize).twice.with(:city, "boston").and_return(true)
          city_events_url.should == "http://boston.example.com/events"
          city_events_path.should == "/events"
        end
      end
    
      it "should raise a routing error if the recognize proc returns false" do
        with_host "www.example.com" do
          ActionController::Routing::Routes.subdomain_procs.should_receive(:recognize).twice.with(:city, "www").and_return(false)
          lambda { city_events_url  }.should raise_error(ActionController::RoutingError)
          lambda { city_events_path }.should raise_error(ActionController::RoutingError)
        end
      end
    
      it "should force the host if the recognize proc returns false but a matching subdomain is supplied" do
        with_host "www.example.com" do
          ActionController::Routing::Routes.subdomain_procs.should_receive(:recognize).twice.with(:city, "boston").and_return(true)
           city_events_url(:subdomain => :boston).should == "http://boston.example.com/events"
          city_events_path(:subdomain => :boston).should == "http://boston.example.com/events"
        end
      end
    
      it "should raise a routing error if the recognize proc returns false and a non-matching subdomain is supplied" do
        with_host "www.example.com" do
          ActionController::Routing::Routes.subdomain_procs.should_receive(:recognize).twice.with(:city, "hobart").and_return(false)
          lambda {  city_events_url(:subdomain => :hobart) }.should raise_error(ActionController::RoutingError)
          lambda { city_events_path(:subdomain => :hobart) }.should raise_error(ActionController::RoutingError)
        end
      end
    
      context "and a generate proc is also defined" do
        before(:each) do
          ActionController::Routing::Routes.generate_subdomain(:city) { |request, context| } # this block will be stubbed
          ActionController::Routing::Routes.subdomain_procs.stub!(:recognize).with(:city, "canberra").and_return(true)
        end
        
        it "should downcase the output of the generate proc" do
          [ :Canberra, "Canberra" ].each do |mixedcase|
            with_host "www.example.com" do
              ActionController::Routing::Routes.subdomain_procs.should_receive(:generate).and_return(mixedcase)
              city_events_path.should == "http://canberra.example.com/events"
            end
          end
        end
    
        it "should generate the URL in a controller using the session" do
          in_controller_with_host "www.example.com" do
            ActionController::Routing::Routes.subdomain_procs.should_receive(:generate).with(:city, request, nil).and_return("canberra")
            city_events_path.should == "http://canberra.example.com/events"
          end
        end
    
        it "should generate the URL in an object using a supplied context" do
          in_object_with_host "www.example.com" do
            ActionController::Routing::Routes.subdomain_procs.should_receive(:generate).with(:city, nil, :city_id => 2 ).and_return("canberra")
            city_events_path(:context => { :city_id => 2 }).should == "http://canberra.example.com/events"
          end
        end
    
        it "should raise any error that the generate proc raises" do
          with_host "www.example.com" do
            error = StandardError.new
            ActionController::Routing::Routes.subdomain_procs.should_receive(:generate).and_raise(error)
            lambda { city_events_path }.should raise_error { |e| e.should == error }
          end
        end
        
        it "should run the recognizer on the generated subdomain and raise a routing error if the subdomain is invalid" do
          ActionController::Routing::Routes.subdomain_procs.stub!(:generate).and_return("www")
          with_host "www.example.com" do
            ActionController::Routing::Routes.subdomain_procs.should_receive(:recognize).with(:city, "www").and_return(false)
            lambda { city_events_path }.should raise_error(ActionController::RoutingError)
          end
        end

        it "should run the recognizer on the generated subdomain and produce the URL if the subdomain is valid" do
          ActionController::Routing::Routes.subdomain_procs.stub!(:generate).and_return("hobart")
          with_host "www.example.com" do
            ActionController::Routing::Routes.subdomain_procs.should_receive(:recognize).with(:city, "hobart").and_return(true)
            lambda { city_events_path }.should_not raise_error
          end
        end
        
        it "should raise a routing error if the generated subdomain has an illegal format" do
          ActionController::Routing::Routes.subdomain_procs.stub!(:recognize).and_return(true)
          with_host "www.example.com" do
            ActionController::Routing::Routes.subdomain_procs.should_receive(:generate).and_return("www!")
            SubdomainRoutes.should_receive(:valid_subdomain?).with("www!").and_return(false)
            lambda { city_events_path }.should raise_error(ActionController::RoutingError)
          end
        end
        
        it "should not raise a routing error if the generated subdomain is blank" do
          ActionController::Routing::Routes.subdomain_procs.stub!(:recognize).and_return(true)
          with_host "www.example.com" do
            ActionController::Routing::Routes.subdomain_procs.should_receive(:generate).and_return("")
            SubdomainRoutes.should_not_receive(:valid_subdomain?)
            lambda { city_events_path }.should_not raise_error
          end
        end

        context "and a subdomain is explicitly requested" do
          it "should not run the generator and return the URL if the requestd subdomain is valid" do
            with_host "www.example.com" do
              ActionController::Routing::Routes.subdomain_procs.should_receive(:recognize).with(:city, "hobart").and_return(true)
              ActionController::Routing::Routes.subdomain_procs.should_not_receive(:generate)
              city_events_path(:subdomain => :hobart).should == "http://hobart.example.com/events"
            end
          end
          
          it "should not run the generator and raise an error if the requestd subdomain is invalid" do
            with_host "www.example.com" do
              ActionController::Routing::Routes.subdomain_procs.should_receive(:recognize).with(:city, "www").and_return(false)
              ActionController::Routing::Routes.subdomain_procs.should_not_receive(:generate)
              lambda { city_events_path(:subdomain => :www) }.should raise_error(ActionController::RoutingError)
            end
          end
        end
      end
    end
  end
end
