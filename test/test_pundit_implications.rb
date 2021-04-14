require 'minitest/autorun'
require 'pundit_implications'

class PunditImplicationsTest < Minitest::Test
  class PolicyClass
    include PunditImplications

    define_implications({
      admin_actions:       [:moderator_actions, :add_event],
      moderator_actions:   [:participant_actions, :add_participant, :edit_event],
      participant_actions: [:view_event, :view_participant, :edit_self],
      add_event:           [:edit_event, :delete_event],
      edit_event:          [:view_event, :edit_participant],
      view_event:          [:list_participants],
      list_participants:   [:view_participant],
      add_participant:     [:edit_participant, :delete_participant],
      edit_participant:    [:view_participant, :edit_self],
      edit_self:           [:view_self]})

    def initialize(*initial_roles)
      initial_roles.each {|role|
        grant role}
    end
  end

  def test_permissions
    # Check for admin permissions
    admin_policy = PolicyClass.new :admin_actions
    assert_equal [:add_event, :add_participant, :admin_actions, :delete_event, :delete_participant,
      :edit_event, :edit_participant, :edit_self, :list_participants,
      :moderator_actions, :participant_actions, :view_event, :view_participant, :view_self],
      admin_policy.granted_list
    assert admin_policy.admin_actions?
    assert admin_policy.add_event?

    # Check for moderator permissions
    moderator_policy = PolicyClass.new :moderator_actions
    assert_equal [:add_participant, :delete_participant,
      :edit_event, :edit_participant, :edit_self, :list_participants, :moderator_actions,
      :participant_actions, :view_event, :view_participant, :view_self],
      moderator_policy.granted_list
    assert !moderator_policy.admin_actions?
    assert !moderator_policy.add_event?
    assert moderator_policy.edit_event?
    assert moderator_policy.edit_self?

    # Check for participant permissions
    participant_policy = PolicyClass.new :participant_actions
    assert_equal [:edit_self, :list_participants, :participant_actions, :view_event, :view_participant, :view_self],
       participant_policy.granted_list
    assert !participant_policy.edit_event?
    assert participant_policy.view_self?

    # No permissions are given
    empty_policy = PolicyClass.new
    assert empty_policy.granted_list.empty?
    assert !empty_policy.view_self?

    # Test for dependency handling
    test_policy = PolicyClass.new
    test_policy.grant :edit_self
    assert_equal [:edit_self, :view_self], test_policy.granted_list
    test_policy.grant :edit_participant
    assert_equal [:edit_participant, :edit_self, :view_participant, :view_self], test_policy.granted_list
  end
end
