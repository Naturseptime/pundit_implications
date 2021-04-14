# Pundit Implications

## Motivation

This is a small gem that simplifies authentification for [Pundit](http://www.rubydoc.info/gems/pundit).

Often many permission levels depend on each other. For example consider an event management system for creating events and adding participants to them.
In our event management system there should be three roles.

* **Administrators** should be capable to create events

* **Moderators** should be capable to add participants to events

* **Participants** should be able to edit their own registration data and see other participants

If we look at permissions in detail we need to specify many additional obvious connections between these permission levels:

* An administrator should be able to do anything a moderator can do.

* An moderator should be able to do anything a participant can do.

* Every person who can add an event should also be able to edit or delete this event.

* Every person who can edit an event should also be able to view this event or add participants to it.

* Every person who can add participants should also able to edit or delete these participants.

and many more.

Handling such dependencies with many different roles and permissions can be quickly get very complex and errorneous.
According to DRY principle we would like to specify such permission implications only one time in our policy class.

Here the `pundit_implications` gem comes into our game.

## Installation

```
gem install pundit_implications
```

```ruby
require 'pundit_implications'
```

## Usage

Include `PunditImplications` in your Pundit policy class:

``` ruby
class MyPolicy
  include PunditImplications
  ...
end
```

Then call `define_implications` inside your policy class.
This function takes a hash map with all permissions and their implications:

Example:

``` ruby
class EventPolicy
  include PunditImplications

  define_implications({
    admin_actions:       [:moderator_actions, :add_event],
    moderator_actions:   [:participant_actions, :add_participant, :edit_event],
    participant_actions: [:view_event, :view_participant, :edit_self],
    add_event:           [:edit_event, :delete_event],
    edit_event:          [:view_event, :add_participants],
    view_event:          [:list_participants],
    list_participants:   [:view_participant],
    add_participant:     [:edit_participant, :delete_participant],
    edit_participant:    [:view_participant, :edit_self],
    edit_self:           [:view_self]})
end
```

Here the line `admin_actions: [:add_event, :moderator_actions]` means:
*"An administrator can do everything a moderator can do and he also can add events (and maybe more)."*

Permissions are transitive, i.e. `:admin_actions` implies also `:participant_actions`.

By calling `define_implications` a bunch of methods like `add_event?`, `edit_event?`, `delete_event?` etc. will be added to your Pundit policy class.

Permissions can be granted with the `grant` method.

```ruby
grant :moderator_actions
```

The grant operation automatically handles all implications given in ``define_implications``

```ruby
grant :moderator_actions
policy(event).edit_event?
=> true
policy(event).view_participant?
=> true
policy(event).delete_event?
=> false
```

A list of all granted actions can be queried with ``granted_list`` (i.e for debugging)