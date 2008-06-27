require File.dirname(__FILE__) + '/../spec_helper'

describe Site do
  include Matchers::ClassExtensions
  fixtures :sites, :sections
  
  before :each do 
    @site = sites(:site_1)
    @home = sections(:home)
    @about = sections(:about)
    @location = sections(:location)
  end
  
  describe 'class extensions:' do
    it 'acts as themed' do
     Site.should act_as_themed
   end
    
    it 'acts as commentable' do
      Site.should act_as_commentable
    end
    
    it 'acts as role context for the admin role' do
      Site.should act_as_role_context(:roles => :admin)
    end
    
    it "serializes its actual permissions" do
      Site.serialized_attributes.should include('permissions')
    end
    
    it 'has default permissions' do
      Site.default_permissions.should == 
        { :site    => { :show => :admin, :create => :superuser, :update => :admin, :destroy => :superuser, :manage => :admin }, 
          :section => { :show => :admin, :create => :admin, :update => :admin, :destroy => :admin }, 
          :theme   => { :show => :admin, :create => :admin, :update => :admin, :destroy => :admin } }
    end
  
    it "has a comments counter" do
      Site.should have_counter(:comments)
    end
  end
  
  describe 'associations:' do
    it "has many sections" do 
      @site.should have_many(:sections) 
    end
  
    it "has many users" do 
      @site.should have_many(:users)
    end
  
    it "has many memberships" do 
      @site.should have_many(:memberships)
    end
  
    it "has many assets" do 
      @site.should have_many(:assets)
    end
  
    it "has many cached_pages" do 
      @site.should have_many(:cached_pages)
    end
  
    describe 'the sections association' do
      it "returns the left-most section that has no parent as the root section" do
        @site.sections.root.should == @home
      end
      
      it "#update_paths! updates all paths" do
        sections = [@home, @about, @location]
        sections.each do |section|      
          section.path = nil
          section.save!
        end
        @site.sections.update_paths!
        sections.map(&:reload)
        sections.collect(&:path).should == ['home', 'home/about', 'home/about/location']
      end
    end
  
    describe 'the assets association' do
      it "#recent finds the six most recent assets" do
        @site.assets.should_receive(:find).with :all, :limit => 6
        @site.assets.recent
      end
    end
    
    it "calls destroy! on associated users when destroyed" do
      user = @site.users.create :name => 'user', :email => 'email@foo.bar', :login => 'login', :password => 'password', :password_confirmation => 'password'
      user.should_not be_false
      @site.destroy
      lambda{ User.find_with_deleted user.id }.should raise_error(ActiveRecord::RecordNotFound)
    end  
  end
  
  describe 'callbacks:' do
    it 'downcases the host before validation' do
      Site.before_validation.should include(:downcase_host)
    end
    
    it 'flushs the page cache after destroy' do
      Site.before_destroy.should include(:flush_page_cache)
    end
  end
  
  describe "validations:" do
    it "validates the presence of a host" do
      @site.should validate_presence_of(:host)
    end
    
    it "validates the presence of a title" do
      @site.should validate_presence_of(:title)
    end
  end
end