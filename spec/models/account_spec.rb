require 'rails_helper'

describe Account do

  it { expect(FactoryGirl.build(:account)).to be_valid }

  describe :destroy_test_contacts do
    let(:date) { DateTime.new(2014,3,23) }

    context "with a nil test_imported_at" do
      let(:account) { FactoryGirl.create(:account, test_imported_at: nil) }

      context "with a contact" do
        let!(:contact) { FactoryGirl.create(:contact, imported_at: nil, account: account)}
        let!(:person) { FactoryGirl.create(:person, account_id: account.id, contact: contact)}

        before(:each) do
          Account.current_id = account
        end

        it { expect(account.contacts.count).to eq(1) }
        it { expect(account.contacts.first).to eq(contact) }
        it { expect(account.contacts.first.contactable).to eq(person) }

        it "works" do
          account.destroy_test_contacts
          expect(account.reload.contacts.count).to eq(1)
        end
      end

    end

    context "with a test_imported_at" do
      let(:account) { FactoryGirl.create(:account, test_imported_at: date) }
      it { expect(account.contacts.count).to eq(0) }

      context "with a contact" do
        let!(:contact) { FactoryGirl.create(:contact, imported_at: date, account: account)}
        let!(:person) { FactoryGirl.create(:person, account_id: account.id, contact: contact)}

        before(:each) do
          Account.current_id = account
        end

        it { expect(account.contacts.count).to eq(1) }
        it { expect(account.contacts.first).to eq(contact) }
        it { expect(account.contacts.first.contactable).to eq(person) }

        it "works" do
          account.destroy_test_contacts
          expect(account.reload.contacts.count).to eq(0)
        end
      end

      context "with a contact that not from last import but an other on date" do
        let(:date) { DateTime.new(2014,3,23, 10, 22) }
        let(:later_date) { DateTime.new(2014,3,23, 14, 52) }
        let!(:contact) { FactoryGirl.create(:contact, imported_at: date, account: account)}
        let!(:contact_to_remove) { FactoryGirl.create(:contact, imported_at: later_date, account: account)}

        let!(:person) { FactoryGirl.create(:person, account_id: account.id, contact: contact)}
        let!(:other_person) { FactoryGirl.create(:person, account_id: account.id, contact: contact_to_remove)}

        let(:account) { FactoryGirl.create(:account, test_imported_at: later_date) }

        before(:each) do
          Account.current_id = account
        end

        it { expect(account.contacts.count).to eq(2) }
        it { expect(account.contacts.sort).to eq([contact, contact_to_remove].sort) }
        it { expect(account.contacts.map(&:contactable).sort).to eq([person, other_person].sort) }

        it "works" do
          account.destroy_test_contacts
          expect(account.reload.contacts.count).to eq(1)
          expect(account.reload.contacts).to eq([contact])
        end
      end
    end
  end

  describe "export" do
    before(:each) { DateTime.stubs(:now).returns(DateTime.new(2010, 12, 30)) }

    context "with an existing account" do
      let(:account) { FactoryGirl.build(:account) }

      context "export_contacts" do
        it { expect(account.export_contacts).to eq(account.export_filename) }

        it { expect(File.stat(account.export_contacts).size).to satisfy {|v| v > 0} }
      end

      describe "export_filename" do
        it { expect(account.export_filename).to eq(File.join(Dir.tmpdir, "#{account.domain}-30122010.zip")) }
      end
    end
  end

  describe "manager?" do
    context "without habilitation, don't throw error" do
      let(:account) { FactoryGirl.create(:account) }
      let(:user) { FactoryGirl.create(:user) }

      it { expect(account.manager?(user)).to be_falsy }
    end
  end
  
  describe "trial_period_ended?" do
    context "account created more than one month" do
      let(:date) { Date.today - 32.days}
      let(:account) { FactoryGirl.create(:account, last_subscription_at: nil, created_at: date) }
      it { expect(account.trial_period_ended?).to be_truthy }
    end

    context "account created less than one month" do
      let(:date) { Date.today - 15.days}
      let(:account) { FactoryGirl.create(:account, last_subscription_at: nil, created_at: date) }
      it { expect(account.trial_period_ended?).to be_falsy }
    end
    
    context "already subscribed" do
      let(:account) { FactoryGirl.create(:account, last_subscription_at: Date.current - 1.day) }
      it { expect(account.trial_period_ended?).to be_falsy }      
    end
    
  end
  
  describe "trial_period_lasts_at" do
    let(:account) { FactoryGirl.create(:account, last_subscription_at: nil, created_at: Date.current) }
    it { expect(account.trial_period_lasts_at).to eq(Date.current + 1.month) }
  end


  describe "subscription_up_to_date?" do
    before(:each) { Date.stubs(:current).returns(Date.new(2015, 9, 1)) }
    
    context "with a last_subscription_at more than one year ago" do
      let(:date) { Date.current.to_date - 366.days } 
      let(:account) { FactoryGirl.create(:account, last_subscription_at: date) }
      it { expect(account.subscription_up_to_date?).to be_falsy }
    end

    context "with a last_subscription_at less than one year ago" do
      let(:date) { Date.current - 100.days } 
      let(:account) { FactoryGirl.create(:account, last_subscription_at: date) }
      it { expect(account.subscription_up_to_date?).to be_truthy }
    end
    
  end
    
  describe "subscription_lasts_at" do
    let(:date) { Date.current - 100.days } 
    let(:account) { FactoryGirl.create(:account, last_subscription_at: date) }
    it { expect(account.subscription_lasts_at).to eq(account.last_subscription_at + 1.year)}
  end
  
  describe "subscription_ended_in_less_than_one_month?" do
    let(:account) { FactoryGirl.create(:account, last_subscription_at: Date.current - 1.year - 1.month + 1.day) }
    it { expect(account.subscription_ended_in_less_than_one_month?).to be_truthy }
  end

  describe "subscription_ended_in_less_than_one_week?" do
    let(:account) { FactoryGirl.create(:account, last_subscription_at: Date.current - 1.year - 1.week + 1.day) }
    it { expect(account.subscription_ended_in_less_than_one_week?).to be_truthy }
  end
  
end
