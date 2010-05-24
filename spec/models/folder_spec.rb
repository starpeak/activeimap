require 'spec_helper'

describe ActiveImap::Folder do
  before :all do
    @connection = ActiveImap::Connection.new ActiveImap::TestCredentials.imap_user, ActiveImap::TestCredentials.imap_password
  end
  
  after :all do
    @connection.logout_and_disconnect if @connection
  end
  
  it "should get the INBOX as first element" do
    inbox = ActiveImap::Folder.first @connection
    inbox.id.should eql 'INBOX'
    inbox.title.should eql 'INBOX'
  end
  
  it "should get the INBOX by id" do
    inbox = ActiveImap::Folder.find(@connection, 'INBOX')
    inbox.id.should eql 'INBOX'
    inbox.title.should eql 'INBOX'    
  end
  
  it "should handle subfolders" do  
    if old_test_folder = ActiveImap::Folder.find(@connection, 'INBOX.rspec_test_folder')
      old_test_folder.destroy
    end
    
    test_folder = ActiveImap::Folder.find(@connection, 'INBOX').create('rspec_test_folder')
    test_folder.title.should eql 'rspec_test_folder'
    test_folder.id.should eql 'INBOX.rspec_test_folder'
    
    test_folder = ActiveImap::Folder.find(@connection, 'INBOX.rspec_test_folder')
    test_folder.title.should eql 'rspec_test_folder'
    test_folder.id.should eql 'INBOX.rspec_test_folder'

    ActiveImap::Folder.find(@connection, 'INBOX').children.should include test_folder
    
    test_folder.destroy
    ActiveImap::Folder.find(@connection, 'INBOX.rspec_test_folder').should be nil
  end
  
  it "should find messages" do
    inbox = ActiveImap::Folder.find(@connection, 'INBOX')
    message = inbox.messages.first
    message.date.class.should be Time
    message.body_text.should be false
  end
end