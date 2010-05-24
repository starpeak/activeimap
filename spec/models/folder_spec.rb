require 'spec_helper'

describe ActiveImap::Folder do
  before :all do
    @connection = ActiveImap::Connection.new ActiveImap::TestCredentials.imap_user, ActiveImap::TestCredentials.imap_password
  end
  
  it "should get the INBOX in different ways" do
    inbox = ActiveImap::Folder.first @connection
    inbox.mailbox.should eql 'INBOX'
    inbox.id.should eql ActiveImap::Folder.mailbox_to_id('INBOX')
    inbox.title.should eql 'INBOX'

    inbox2 = ActiveImap::Folder.find_by_mailbox(@connection, 'INBOX')
    inbox2.mailbox.should eql 'INBOX'
    inbox2.id.should eql ActiveImap::Folder.mailbox_to_id('INBOX')
    inbox2.title.should eql 'INBOX'    
    
    (inbox == inbox2).should be true
  end
  
  
  
  it "should handle subfolders" do  
    %w(INBOX.rspec_test_folder INBOX.rspec_test_folder_2).each do |old_test_folder_name|
      if old_test_folder = ActiveImap::Folder.find_by_mailbox(@connection, old_test_folder_name)
        old_test_folder.destroy
      end
    end
    
    test_folder = ActiveImap::Folder.find_by_mailbox(@connection, 'INBOX').create('rspec_test_folder')
    test_folder.title.should eql 'rspec_test_folder'
    test_folder.mailbox.should eql 'INBOX.rspec_test_folder'
    
    test_folder = ActiveImap::Folder.find_by_mailbox(@connection, 'INBOX.rspec_test_folder')
    test_folder.title.should eql 'rspec_test_folder'
    test_folder.mailbox.should eql 'INBOX.rspec_test_folder'

    ActiveImap::Folder.find_by_mailbox(@connection, 'INBOX').children.should include test_folder
    (test_folder.parent == ActiveImap::Folder.find_by_mailbox(@connection, 'INBOX')).should be true
    
    test_folder.update_attribute :title, 'rspec_test_folder_2'
    test_folder.id.should eql ActiveImap::Folder.mailbox_to_id('INBOX.rspec_test_folder_2')
    ActiveImap::Folder.find_by_mailbox(@connection, 'INBOX.rspec_test_folder').should be nil
    
    test_folder.destroy
    ActiveImap::Folder.find_by_mailbox(@connection, 'INBOX.rspec_test_folder_2').should be nil
  end
  
  it "should find messages" do
    inbox = ActiveImap::Folder.find_by_mailbox(@connection, 'INBOX')
    message = inbox.messages.first
    message.date.class.should be Time
    message.body_text.should be false
  end
end