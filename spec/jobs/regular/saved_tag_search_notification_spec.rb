# frozen_string_literal: true

require 'rails_helper'
require 'discourse_tagging'

describe Jobs::SavedSearchNotification do
  let(:user) { Fabricate(:user, trust_level: 1) }
  let(:tl2_user) { Fabricate(:user, trust_level: 2) }
  let(:tag1) { Fabricate(:tag, name: "fun") }
  let(:tag2) { Fabricate(:tag, name: "fun2") }
  fab!(:category) { Fabricate(:category) }

  before do
    SearchIndexer.enable
    SiteSetting.tagging_enabled = true
    SiteSetting.min_trust_to_create_tag = 0
    SiteSetting.min_trust_level_to_tag_topics = 0
  end

  it "does nothing if user has no saved tag searches" do
    expect {
      described_class.new.execute(user_id: user.id)
    }.to_not change { Topic.count }
  end

  context "with saved tag searches" do
    before do
      user.custom_fields["saved_tag_searches"] = { "tag_searches" => ["#{category.id},#{tag1.name}"] }
      user.save!
    end

    it "doesn't create a PM for the user if no results are found" do
      expect {
        described_class.new.execute(user_id: user.id)
      }.to_not change { Topic.count }
    end

    context "first search" do
      context "with recent post" do
        let!(:topic) { Fabricate(:topic, category: category, tags: [tag1]) }
        let!(:post) { Fabricate(:post, topic: topic ) }

        it "creates a PM if recent results are found" do
          expect(topic.category_id).to eq(category.id)
          expect(topic.tags).to include(tag1)
          puts "topic cat id: #{topic.category_id}"
          puts "topic cat tags: #{topic.tags.first.name}"
          puts "tag searches: #{user.custom_fields["saved_tag_searches"]["tag_searches"]}"
          expect(user.custom_fields["saved_tag_searches"]["tag_searches"].first.split(',')[0].to_i).to eq(category.id)
          expect {
            described_class.new.execute(user_id: user.id)
          }.to change { Topic.where(subtype: TopicSubtype.system_message).count }.by(1)
        end

        # it "creates a PM for each cat/tag" do
        #   topic2 = Fabricate(:topic, user: tl2_user, raw: "Another topic with the really good tag.")
        #   expect {
        #     described_class.new.execute(user_id: user.id)
        #   }.to change { Topic.where(subtype: TopicSubtype.system_message).count }.by(2)
        # end

        # it "does nothing if trust level is too low" do
        #   SiteSetting.saved_searches_min_trust_level = 2
        #   expect {
        #     described_class.new.execute(user_id: user.id)
        #   }.to_not change { Topic.count }
        # end

        # it "doesn't notify for suspended users" do
        #   user.update!(suspended_at: 1.hour.ago, suspended_till: 20.years.from_now)
        #   expect {
        #     described_class.new.execute(user_id: user.id)
        #   }.to_not change { Topic.count }
        # end

        # it "doesn't notify for deactivated users" do
        #   user.deactivate(Fabricate(:admin))
        #   expect {
        #     described_class.new.execute(user_id: user.id)
        #   }.to_not change { Topic.count }
        # end
      end

      # it "doesn't create a PM if results are too old" do
      #   topic = Fabricate(:topic, user: tl2_user, created_at: 48.hours.ago)
      #   post = Fabricate(:post, topic: topic, user: tl2_user, raw: "Check out these coupon codes for cool things.", created_at: 48.hours.ago)
      #   expect {
      #     described_class.new.execute(user_id: user.id)
      #   }.to_not change { Topic.count }
      # end

      # it "doesn't notify for my own posts" do
      #   topic = Fabricate(:topic, user: user)
      #   post = Fabricate(:post, topic: topic, user: user, raw: "Check out these coupon codes for cool things.")
      #   expect {
      #     described_class.new.execute(user_id: user.id)
      #   }.to_not change { Topic.count }
      # end

      # it "doesn't notify for small actions" do
      #   topic = Fabricate(:topic, user: user)
      #   post = Fabricate(:post, topic: topic, user: tl2_user, raw: "Check out these eat deals for cool things.")
      #   post = Fabricate(:post, topic: topic, user: Fabricate(:admin), raw: "Moved this to coupon category.", post_type: Post.types[:small_action], post_number: 2)
      #   expect {
      #     described_class.new.execute(user_id: user.id)
      #   }.to_not change { Topic.count }
      # end
    end

    # context "not the first search" do
    #   let(:topic) { Fabricate(:topic, user: tl2_user) }
    #   let!(:post)  {
    #     Fabricate(
    #       :post,
    #       topic: topic,
    #       user: tl2_user,
    #       raw: "Check out these coupon codes for cool things.")
    #   }

    #   before do
    #     described_class.new.execute(user_id: user.id)
    #   end

    #   it "doesn't notify about the same search results" do
    #     expect {
    #       described_class.new.execute(user_id: user.id)
    #     }.to_not change { Topic.where(subtype: TopicSubtype.system_message).count }
    #   end

    #   it "notifies about new result in the same topic" do
    #     post2 = Fabricate(:post, topic: topic, user: tl2_user, raw: "Everyone loves a good coupon I think.")
    #     expect {
    #       described_class.new.execute(user_id: user.id)
    #       pm = Topic.where(title: I18n.t('system_messages.saved_searches_notification.subject_template', term: 'coupon')).first
    #       expect(pm.posts.count).to eq(2)
    #     }.to_not change { Topic.where(subtype: TopicSubtype.system_message).count }
    #   end

    #   it "creates a new topic if it's for a different search term" do
    #     post2 = Fabricate(:post, topic: topic, user: tl2_user, raw: "Everyone loves a good discount I think.")
    #     expect {
    #       described_class.new.execute(user_id: user.id)
    #       pm = Topic.where(title: I18n.t('system_messages.saved_searches_notification.subject_template', term: 'discount')).first
    #       expect(pm.posts.count).to eq(1)
    #     }.to change { Topic.where(subtype: TopicSubtype.system_message).count }.by(1)
    #   end

    #   it "creates a new topic if the previous one was deleted" do
    #     pm = Topic.where(title: I18n.t('system_messages.saved_searches_notification.subject_template', term: 'coupon')).first
    #     pm.trash!
    #     post2 = Fabricate(:post, topic: topic, user: tl2_user, raw: "Everyone loves a good coupon I think.")
    #     expect {
    #       described_class.new.execute(user_id: user.id)
    #       pm = Topic.where(title: I18n.t('system_messages.saved_searches_notification.subject_template', term: 'coupon')).last
    #       expect(pm.posts.count).to eq(1)
    #     }.to change { Topic.where(subtype: TopicSubtype.system_message).count }.by(1)
    #   end
    # end
  end
end
