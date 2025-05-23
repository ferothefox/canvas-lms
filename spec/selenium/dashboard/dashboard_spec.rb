# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative "../common"
require_relative "../helpers/notifications_common"
require_relative "pages/k5_dashboard_page"
require_relative "pages/dashboard_page"

describe "dashboard" do
  include NotificationsCommon
  include K5DashboardPageObject
  include DashboardPage
  include_context "in-process server selenium tests"

  shared_examples_for "load events list" do
    it "loads events list sidebar", priority: "2" do
      get "/"
      wait_for_ajaximations
      expect(f(".events_list")).to be_displayed
    end
  end

  context "as a student" do
    before do
      course_with_student_logged_in(active_all: true)
      @course.default_view = "feed"
      @course.save!
    end

    def create_announcement
      Announcement.create!(context: @course,
                           title: "hey all read this k",
                           message: "announcement")
    end

    it "does not show announcement stream items without permissions" do
      @course.account.role_overrides.create!(role: student_role,
                                             permission: "read_announcements",
                                             enabled: false)

      get "/"
      f("#DashboardOptionsMenu_Container button").click
      fj('span[role="menuitemradio"]:contains("Recent Activity")').click
      expect(f(".no_recent_messages")).to include_text("No Recent Messages")
    end

    def click_recent_activity_header(type = "announcement")
      f(".stream-#{type} .stream_header").click
    end

    def assert_recent_activity_category_closed(type = "announcement")
      expect(f(".stream-#{type} .details_container")).not_to be_displayed
    end

    def assert_recent_activity_category_is_open(type = "announcement")
      expect(f(".stream-#{type} .details_container")).to be_displayed
    end

    def click_recent_activity_course_link(type = "announcement")
      f(".stream-#{type} .links a").click
    end

    # so we can click the link w/o a page load
    def disable_recent_activity_header_course_link
      driver.execute_script <<~JS
        $('.stream-announcement .links a').attr('href', '#');
      JS
    end

    it "expand/collapses recent activity category", priority: "1" do
      create_announcement
      get "/"
      f("#DashboardOptionsMenu_Container button").click
      fj('span[role="menuitemradio"]:contains("Recent Activity")').click
      assert_recent_activity_category_closed
      click_recent_activity_header
      assert_recent_activity_category_is_open
      click_recent_activity_header
      assert_recent_activity_category_closed
    end

    it "does not expand category when a course/group link is clicked", priority: "2" do
      create_announcement
      get "/"
      f("#DashboardOptionsMenu_Container button").click
      fj('span[role="menuitemradio"]:contains("Recent Activity")').click
      assert_recent_activity_category_closed
      disable_recent_activity_header_course_link
      click_recent_activity_course_link
      assert_recent_activity_category_closed
    end

    it "should update the item count on stream item hide"
    it "should remove the stream item category if all items are removed"

    it "shows conversation stream items on the dashboard", priority: "1" do
      c = User.create.initiate_conversation([@user, User.create])
      c.add_message("test")
      c.add_participants([User.create])

      items = @user.stream_item_instances
      expect(items.size).to eq 1

      get "/"
      f("#DashboardOptionsMenu_Container button").click
      fj('span[role="menuitemradio"]:contains("Recent Activity")').click
      expect(ff("#conversation-details tbody tr").size).to eq 1
    end

    it "shows an assignment stream item under Recent Activity in dashboard", priority: "1" do
      setup_notification(@student, name: "Assignment Created")
      assignment_model({ submission_types: ["online_text_entry"], course: @course })
      get "/"
      f("#DashboardOptionsMenu_Container button").click
      fj('span[role="menuitemradio"]:contains("Recent Activity")').click
      find(".toggle-details").click
      expect(fj('.fake-link:contains("Unnamed")')).to be_present
    end

    it "shows account notifications on the dashboard", priority: "1" do
      u = User.create!
      a1 = @course.account.announcements.create!(subject: "test",
                                                 message: "hey there",
                                                 user: u,
                                                 start_at: Time.zone.today - 1.day,
                                                 end_at: Time.zone.today + 1.day)
      a2 = @course.account.announcements.create!(subject: "test 2",
                                                 message: "another annoucement",
                                                 user: u,
                                                 start_at: Time.zone.today - 2.days,
                                                 end_at: Time.zone.today + 1.day)

      get "/"
      f("#DashboardOptionsMenu_Container button").click
      fj('span[role="menuitemradio"]:contains("Recent Activity")').click
      messages = ff("#dashboard .account_notification .notification_message")
      expect(messages.size).to eq 2
      expect(messages[0].text).to eq a2.message
      expect(messages[1].text).to eq a1.message
    end

    it "interpolates the user's domain in global notifications" do
      announcement = @course.account.announcements.create!(message: "blah blah http://random-survey-startup.ly/?some_GET_parameter_by_which_to_differentiate_results={{ACCOUNT_DOMAIN}}",
                                                           subject: "test",
                                                           user: User.create!,
                                                           start_at: Time.zone.today,
                                                           end_at: Time.zone.today + 1.day)

      get "/"
      expect(fj("#dashboard .account_notification .notification_message").text).to eq announcement.message.gsub("{{ACCOUNT_DOMAIN}}", @course.account.domain)
    end

    it "interpolates the user's id in global notifications" do
      announcement = @course.account.announcements.create!(message: "blah blah http://random-survey-startup.ly/?surveys_are_not_really_anonymous={{CANVAS_USER_ID}}",
                                                           subject: "test",
                                                           user: User.create!,
                                                           start_at: Time.zone.today,
                                                           end_at: Time.zone.today + 1.day)
      get "/"
      expect(fj("#dashboard .account_notification .notification_message").text).to eq announcement.message.gsub("{{CANVAS_USER_ID}}", @user.global_id.to_s)
    end

    it "shows appointment stream items on the dashboard", priority: "2" do
      skip "we need to add this stuff back in"
      Notification.create(name: "Appointment Group Published", category: "Appointment Availability")
      Notification.create(name: "Appointment Group Updated", category: "Appointment Availability")
      Notification.create(name: "Appointment Reserved For User", category: "Appointment Signups")
      @me = @user
      student_in_course(active_all: true, course: @course)
      @other_student = @user
      @user = @me

      @group = group_category.groups.create(context: @course)
      @group.users << @other_student << @user
      # appointment group publish notification and signup notification
      appointment_participant_model(course: @course, participant: @group, updating_user: @other_student)
      # appointment group update notification
      @appointment_group.update(new_appointments: [[Time.now.utc + 2.hours, Time.now.utc + 3.hours]])

      get "/"
      expect(ffj(".topic_message .communication_message.dashboard_notification").size).to eq 3
      # appointment group publish and update notifications
      expect(ffj(".communication_message.message_appointment_group_#{@appointment_group.id}").size).to eq 2
      # signup notification
      expect(ffj(".communication_message.message_group_#{@group.id}").size).to eq 1
    end

    describe "course menu" do
      before do
        @course.update(start_at: 2.days.from_now, conclude_at: 4.days.from_now, restrict_enrollments_to_course_dates: false)
        Enrollment.update_all(created_at: 1.minute.ago)
        get "/"
      end

      it "displays course name in course menu", priority: "1" do
        f("#global_nav_courses_link").click
        expect(driver.current_url).not_to match(%r{/courses$})
        expect(fj("[aria-label='Courses tray'] h2:contains('Courses')")).to be_displayed
        wait_for_ajax_requests
        expect(fj("[aria-label='Courses tray'] a:contains('#{@course.name}')")).to be_displayed
      end

      it "displays student groups in header nav", priority: "2" do
        group = Group.create!(name: "group1", context: @course)
        group.add_user(@user)

        other_unpublished_course = course_factory
        other_group = Group.create!(name: "group2", context: other_unpublished_course)
        other_group.add_user(@user)

        get "/"

        f("#global_nav_groups_link").click
        expect(fj("[aria-label='Groups tray'] h2:contains('Groups')")).to be_displayed
        wait_for_ajax_requests

        list = fj("[aria-label='Groups tray']")
        expect(list).to include_text(group.name)
        expect(list).to_not include_text(other_group.name)
      end

      it "goes to a course when clicking a course link from the menu", priority: "1" do
        f("#global_nav_courses_link").click
        fj("[aria-label='Courses tray'] li a:contains('#{@course.name}')").click
        expect(driver.current_url).to match "/courses/#{@course.id}"
      end
    end

    it "displays scheduled web conference in stream", priority: "1" do
      PluginSetting.create!(name: "wimba", settings: { "domain" => "wimba.instructure.com" })

      # NOTE: recently changed the behavior here: conferences only display on
      # the course page, and they only display when they are in progress
      @conference = @course.web_conferences.build({ title: "my Conference", conference_type: "Wimba", duration: 60 })
      @conference.user = @user
      @conference.save!
      @conference.restart
      @conference.add_initiator(@user)
      @conference.add_invitee(@user)
      @conference.save!

      get "/courses/#{@course.to_param}"
      expect(f(".conference .notification_message")).to include_text(@conference.title)
    end

    it "ends conferences from stream", priority: "1" do
      skip_if_safari(:alert)
      PluginSetting.create!(name: "wimba", settings: { "domain" => "wimba.instructure.com" })

      course_with_teacher_logged_in
      @course.default_view = "feed"
      @course.save!

      @conference = @course.web_conferences.build({ title: "my Conference", conference_type: "Wimba", duration: nil })
      @conference.user = @user
      @conference.save!
      @conference.restart
      @conference.add_initiator(@user)
      @conference.add_invitee(@user)
      @conference.save!

      get "/courses/#{@course.to_param}"
      f(".conference .close_conference_link").click
      expect(alert_present?).to be_truthy
      accept_alert
      wait_for_ajaximations
      expect(f(".conference")).to_not be_displayed
      @conference.reload
      expect(@conference).to be_finished
    end

    it "creates an announcement for the first course that is not visible in the second course", priority: "1" do
      @context = @course
      announcement_model({ title: "hey all read this k", message: "announcement" })
      @second_course = Course.create!(name: "second course")
      @second_course.offer!
      @second_course.default_view = "feed"
      @second_course.save!
      # add teacher as a user
      u = User.create!
      u.register!
      e = @course.enroll_teacher(u)
      e.workflow_state = "active"
      e.save!
      @second_enrollment = @second_course.enroll_student(@user)
      @enrollment.workflow_state = "active"
      @enrollment.save!
      @second_course.reload
      Enrollment.update_all(created_at: 1.minute.ago) # need to make created_at and updated_at different

      get "/"
      expect(f("#content")).not_to contain_css(".no_recent_messages")

      get "/courses/#{@second_course.id}"
      expect(f(".no_recent_messages")).to include_text("No Recent Messages")
    end

    it "validates the functionality of soft concluded courses in dropdown", priority: "1" do
      course_with_student(active_all: true, course_name: "a_soft_concluded_course", user: @user)
      c1 = @course
      c1.conclude_at = 1.week.ago
      c1.start_at = 1.month.ago
      c1.restrict_enrollments_to_course_dates = true
      c1.save!
      get "/"

      f("#global_nav_courses_link").click
      expect(fj("[aria-label='Courses tray'] h2:contains('Courses')")).to be_displayed
      expect(f("[aria-label='Courses tray']")).not_to include_text(c1.name)
    end

    it "shows recent feedback and it should work", priority: "1" do
      assign = @course.assignments.create!(title: "hi", due_at: 1.day.ago, points_possible: 5)
      assign.grade_student(@student, grade: "4", grader: @teacher)

      get "/"
      wait_for_ajaximations

      expect(f(".recent_feedback a")).to have_attribute("href", %r{courses/#{@course.id}/assignments/#{assign.id}/submissions/#{@student.id}})
      f(".recent_feedback a").click
      wait_for_ajaximations

      # submission page should load
      expect(f("h1").text).to eq "Submission Details"
    end

    it "validates the functionality of soft concluded courses on courses page", priority: "1" do
      term = EnrollmentTerm.new(name: "Super Term", start_at: 1.month.ago, end_at: 1.week.ago)
      term.root_account_id = @course.root_account_id
      term.save!
      c1 = @course
      c1.name = "a_soft_concluded_course"
      c1.update!(enrollment_term: term)
      c1.reload
      get "/courses"
      expect(fj("#past_enrollments_table a[href='/courses/#{@course.id}']")).to include_text(c1.name)
    end

    context "course menu customization" do
      it "always has a link to the courses page (with customizations)", priority: "1" do
        course_with_teacher({ user: @user, active_course: true, active_enrollment: true })
        get "/"
        f("#global_nav_courses_link").click
        expect(fj('[aria-label="Courses tray"] a:contains("All Courses")')).to be_present
      end
    end
  end

  context "as a teacher" do
    before do
      course_with_teacher_logged_in(active_cc: true)
    end

    it_behaves_like "load events list"

    context "restricted future courses" do
      before :once do
        term = EnrollmentTerm.new(name: "Super Term", start_at: 1.week.from_now, end_at: 1.month.from_now)
        term.root_account_id = Account.default.id
        term.save!
        course_with_student(active_all: true)
        @c1 = @course
        @c1.name = "a future course"
        @c1.update!(enrollment_term: term)

        course_with_student(active_course: true, user: @student)
        @c2 = @course
        @c2.name = "a restricted future course"
        @c2.restrict_student_future_view = true
        @c2.update!(enrollment_term: term)
      end

      before do
        user_session(@student)
      end

      it "shows future courses (even if restricted) to students on courses page" do
        get "/courses"
        expect(fj("#future_enrollments_table a[href='/courses/#{@c1.id}']")).to include_text(@c1.name)

        expect(f("#content")).not_to contain_css("#future_enrollments_table a[href='/courses/#{@c2.id}']") # should not have a link
        expect(f("#future_enrollments_table")).to include_text(@c2.name) # but should still show restricted future enrollment
      end

      it "does not show restricted future courses to students on courses page if configured on account" do
        a = @c2.account
        a.settings[:restrict_student_future_listing] = { value: true }
        a.save!
        get "/courses"
        expect(fj("#future_enrollments_table a[href='/courses/#{@c1.id}']")).to include_text(@c1.name)
        expect(f("#future_enrollments_table")).to_not include_text(@c2.name) # shouldn't be included at all
      end
    end

    it "displays assignment to grade in to do list for a teacher", priority: "1" do
      assignment = assignment_model({ submission_types: "online_text_entry", course: @course })
      student = user_with_pseudonym(active_user: true, username: "student@example.com", password: "qwertyuiop")
      @course.enroll_user(student, "StudentEnrollment", enrollment_state: "active")
      assignment.reload
      assignment.submit_homework(student, { submission_type: "online_text_entry", body: "ABC" })
      assignment.reload

      User.where(id: @teacher).update_all(updated_at: 1.day.ago) # ensure cache refresh
      enable_cache do
        get "/"

        # verify assignment is in to do list
        expect(f(".to-do-list > li")).to include_text("Grade " + assignment.title)

        student.enrollments.first.destroy

        get "/"

        # verify todo list is updated
        expect(f("#content")).not_to contain_css(".to-do-list > li")
      end
    end
  end

  context "as an observer" do
    before :once do
      @course1 = course_factory(active_all: true, course_name: "Course 1")
      @course2 = course_factory(active_all: true, course_name: "Course 2")
      @student1 = user_factory(active_all: true, name: "Student 1")
      @student2 = user_factory(active_all: true, name: "Student 2")
      @observer = user_factory(active_all: true)
      @course1.enroll_student(@student1, enrollment_state: :active)
      @course2.enroll_student(@student2, enrollment_state: :active)
      @course1.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student1.id })
      @course2.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student2.id })
    end

    before do
      user_session(@observer)
      driver.manage.delete_cookie("#{ObserverEnrollmentsHelper::OBSERVER_COOKIE_PREFIX}#{@observer.id}")
    end

    context "observed students picker" do
      it "loads only the first student's cards and shows them in the picker" do
        get "/"
        expect(card_container).to include_text("Course 1")
        expect(card_container).not_to include_text("Course 2")
        expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("Student 1")
      end

      it "loads the second student's cards when selected in the picker" do
        get "/"
        expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("Student 1")
        click_observed_student_option("Student 2")
        wait_for_ajaximations
        expect(card_container).to include_text("Course 2")
        expect(card_container).not_to include_text("Course 1")
        expect(element_value_for_attr(observed_student_dropdown, "value")).to eq("Student 2")
      end
    end
  end

  context "start course button" do
    context "as a teacher" do
      before :once do
        course_with_teacher(active_all: true)
      end

      before do
        user_session(@teacher)
      end

      it "does not show" do
        get "/"
        expect(f("body")).not_to contain_jqcss("#start_new_course")
      end

      it "launches classic 'create course modal' if teachers can create courses" do
        Account.default.update_attribute(:settings, { teachers_can_create_courses: true })
        get "/"
        f("#start_new_course").click
        expect(fj('.ui-dialog-title:contains("Start a New Course")')).to be_displayed
      end
    end

    context "as a sub-admin" do
      before :once do
        sub_acc = Account.create!(name: "sub_account", parent_account: Account.default)
        @sub_admin = account_admin_user(account: sub_acc)
      end

      before do
        user_session(@sub_admin)
      end

      it "does not show" do
        get "/"
        expect(f("body")).not_to contain_jqcss("#start_new_course")
      end
    end

    context "as teacher who is also a sub-admin" do
      before :once do
        course_with_teacher(active_all: true)
        sub_acc = Account.create!(name: "sub_account", parent_account: Account.default)
        @teacher.account.account_users.create!(user: @teacher, account: sub_acc)
      end

      before do
        user_session(@teacher)
      end

      it "launches classic 'create course modal'" do
        get "/"
        f("#start_new_course").click
        expect(fj('.ui-dialog-title:contains("Start a New Course")')).to be_displayed
      end
    end

    context "as a student" do
      before :once do
        student_in_course(active_all: true, course: @course)
      end

      before do
        user_session(@student)
      end

      it "does not show" do
        get "/"
        expect(f("body")).not_to contain_jqcss("#start_new_course")
      end
    end

    context "with create_course_subaccount_picker enabled" do
      before :once do
        Account.default.enable_feature!(:create_course_subaccount_picker)
      end

      context "as a teacher" do
        before :once do
          course_with_teacher(active_all: true)
        end

        before do
          user_session(@teacher)
        end

        it "does not show" do
          get "/"
          expect(f("body")).not_to contain_jqcss("#start_new_course")
        end

        it "launches new 'create course modal' if teachers can create courses" do
          Account.default.update_attribute(:settings, { teachers_can_create_courses_anywhere: false, teachers_can_create_courses: true })
          get "/"
          f("#start_new_course").click
          expect(fj('h2:contains("Create Course")')).to be_displayed
          expect(f("body")).not_to contain_jqcss("span:contains('Which account will this course be associated with?')")
          expect(f("body")).not_to contain_jqcss(".flashalert-message")
        end
      end

      context "as a sub-admin" do
        before :once do
          sub_acc = Account.create!(name: "sub_account", parent_account: Account.default)
          @sub_admin = account_admin_user(account: sub_acc)
        end

        before do
          user_session(@sub_admin)
        end

        it "launches new 'create course modal' if teachers can create courses" do
          get "/"
          f("#start_new_course").click
          expect(fj('h2:contains("Create Course")')).to be_displayed
          expect(f("body")).not_to contain_jqcss(".flashalert-message")
        end
      end

      context "as teacher who is also a sub-admin" do
        before :once do
          sub_acc = Account.create!(name: "sub_account", parent_account: Account.default)
          sub_acc_admin = account_admin_user(account: sub_acc)
          course_with_teacher(user: sub_acc_admin, active_all: true)
        end

        before do
          user_session(@teacher)
        end

        it "launches new 'create course modal'" do
          get "/"
          f("#start_new_course").click
          expect(fj('h2:contains("Create Course")')).to be_displayed
          expect(f("body")).not_to contain_jqcss(".flashalert-message")
        end

        it "ignores teacher mcc restrictions" do
          Account.default.update_attribute(:settings, { teachers_can_create_courses_anywhere: false, teachers_can_create_courses: true })
          get "/"
          f("#start_new_course").click
          expect(fj('h2:contains("Create Course")')).to be_displayed
          expect(f("body")).to contain_jqcss("span:contains('Which account will this course be associated with?')")
          expect(f("body")).not_to contain_jqcss(".flashalert-message")
        end
      end

      context "as a restricted root admin who is also a sub-admin" do
        it "show the proper picker regardless of lack of root permissions" do
          Account.default.update_attribute(:settings, { no_enrollments_can_create_courses: true })
          acc_admin = account_admin_user_with_role_changes(account: Account.default, role_changes: { manage_courses_add: false })
          sub_acc = Account.create!(name: "sub_account", parent_account: Account.default)
          account_with_role_changes(account: sub_acc, role_changes: { manage_courses_add: true })
          acc_admin.account_users.create!(account: sub_acc)
          user_session(acc_admin)
          get "/"
          f("#start_new_course").click
          expect(fj('h2:contains("Create Course")')).to be_displayed
          expect(f("body")).to contain_jqcss("span:contains('Which account will this course be associated with?')")
        end
      end

      context "as a student" do
        before :once do
          student_in_course(active_all: true, course: @course)
        end

        before do
          user_session(@student)
        end

        it "does not show" do
          get "/"
          expect(f("body")).not_to contain_jqcss("#start_new_course")
        end
      end
    end
  end
end
