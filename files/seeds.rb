# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

administrator = Administrator.create!(
  email: "admin@example.com",
  password: "password",
)
Credential.create!(
  consumer_key: "key",
  consumer_secret: "secret",
  administrator_id: administrator.id,
)

tool_consumer = ToolConsumer.find_or_create_by(
  instance_guid: "07adb3e60637ff02d9ea11c7c74f1ca921699bd7.canvas.instructure.com",
  instance_name: "Free For Teacher",
  instance_description: nil,
  instance_url: nil,
  instance_contact_email: "notifications@instructure.com",
)
puts "Add ToolConsumer"
Consumption.find_or_create_by(
  tool_consumer_id: tool_consumer.id,
  credential_id: Credential.first,
)
puts "Add Consumption"
context = Context.find_or_create_by(
  title: "LTI Test",
  id_from_tc: "4a91e348a7026222b98bd2af87be0aeee085eb0f",
)
puts "Add Context"
instructor = User.find_or_create_by(
  first_name: "Instructor",
  last_name: "Test",
  preferred_name: "Preferred Instructor",
  id_from_tc: "bd815e718b9d924bdd6ceb708bc2c6eb4ab0754b",
)
puts "Add Instructor User"
student = User.find_or_create_by(
  first_name: "Student",
  last_name: "Test",
  preferred_name: "Preferred Student",
  id_from_tc: "03bdb94e0a8fc857ef71280eaf0919199a841bc0",
)
puts "Add Student User"
instructor_enrollment = Enrollment.find_or_create_by(
  roles: "Instructor",
  context_id: context.id,
  user_id: instructor.id,
)
puts "Add Instructor Enrollment"
student_enrollment = Enrollment.find_or_create_by(
  roles: "Learner",
  context_id: context.id,
  user_id: student.id,
)
puts "Add Student Enrollment"
resource = Resource.find_or_create_by(
  id_from_tc: "fa070692257fc1b67ce7461e18cecd418a5286d5",
  context_id: context.id,
  title: "#{Rails.application.class.parent.to_s} (dev)",
)
puts "Add Resource"
Submission.find_or_create_by(
  enrollment_id: instructor_enrollment.id,
  resource_id: resource.id,
  score: 0.0,
)
puts "Add Instructor Submission"
Submission.find_or_create_by(
  enrollment_id: student_enrollment.id,
  resource_id: resource.id,
  score: 0.0,
)
puts "Add Student Submission"
Launch.find_or_create_by(
  context_id: context.id,
  tool_consumer_id: tool_consumer.id,
  user_id: instructor.id,
  enrollment_id: instructor_enrollment.id,
  resource_id: resource.id,
  payload:
   { "roles" => "Instructor",
     "action" => "find_or_create_by",
     "user_id" => "bd815e718b9d924bdd6ceb708bc2c6eb4ab0754b",
     "ext_roles" =>
     "urn:lti:instrole:ims/lis/Instructor,urn:lti:role:ims/lis/Instructor,urn:lti:sysrole:ims/lis/User",
     "context_id" => "4a91e348a7026222b98bd2af87be0aeee085eb0f",
     "controller" => "launches",
     "lti_version" => "LTI-1p0",
     "oauth_nonce" => "WbMREBdVJOdwdva0VZmyMepxYigKZitAJzxJkqdV0",
     "context_label" => "LTI Test",
     "context_title" => "LTI Test",
     "oauth_version" => "1.0",
     "oauth_callback" => "about:blank",
     "oauth_signature" => "NdQ/tmTXCEO/s+MWq1WgcsyHdcM=",
     "oauth_timestamp" => "1562960406",
     "lti_message_type" => "basic-lti-launch-request",
     "resource_link_id" => "fa070692257fc1b67ce7461e18cecd418a5286d5",
     "oauth_consumer_key" => "key",
     "resource_link_title" => "#{Rails.application.class.parent.to_s} (dev)",
     "ext_lti_assignment_id" => "46e09daf-bcdf-4bc0-bf30-1f15994d6346",
     "oauth_signature_method" => "HMAC-SHA1",
     "lis_outcome_service_url" => "https://canvas.instructure.com/api/lti/v1/tools/318968/grade_passback",
     "launch_presentation_locale" => "en",
     "tool_consumer_info_version" => "cloud",
     "tool_consumer_instance_guid" => "07adb3e60637ff02d9ea11c7c74f1ca921699bd7.canvas.instructure.com",
     "tool_consumer_instance_name" => "Free For Teacher",
     "ext_ims_lis_basic_outcome_url" =>
     "https://canvas.instructure.com/api/lti/v1/tools/318968/ext_grade_passback",
     "custom_canvas_assignment_title" => "#{Rails.application.class.parent.to_s} (dev)",
     "custom_canvas_enrollment_state" => "active",
     "launch_presentation_return_url" => "https://canvas.instructure.com/courses/1588231/assignments",
     "ext_outcomes_tool_placement_url" =>
     "https://canvas.instructure.com/api/lti/v1/turnitin/outcomes_placement/318968",
     "ext_outcome_data_values_accepted" => "url,text",
     "launch_presentation_document_target" => "iframe",
     "tool_consumer_instance_contact_email" => "notifications@instructure.com",
     "tool_consumer_info_product_family_code" => "canvas",
     "ext_outcome_result_total_score_accepted" => "true",
     "custom_canvas_assignment_points_possible" => "0",
     "ext_outcome_submission_submitted_at_accepted" => "true" },
)
puts "Add Instructor Launch"
Launch.find_or_create_by(
  context_id: context.id,
  tool_consumer_id: tool_consumer.id,
  user_id: student.id,
  enrollment_id: student_enrollment.id,
  resource_id: resource.id,
  payload:
   { "roles" => "Learner",
     "action" => "find_or_create_by",
     "user_id" => "03bdb94e0a8fc857ef71280eaf0919199a841bc0",
     "ext_roles" =>
     "urn:lti:instrole:ims/lis/Student,urn:lti:role:ims/lis/Learner,urn:lti:sysrole:ims/lis/User",
     "context_id" => "4a91e348a7026222b98bd2af87be0aeee085eb0f",
     "controller" => "launches",
     "lti_version" => "LTI-1p0",
     "oauth_nonce" => "rFnu3KWkMjOyk1NPOV9eptwzuEDs5DmvDLqGcHwDuF0",
     "context_label" => "LTI Test",
     "context_title" => "LTI Test",
     "oauth_version" => "1.0",
     "oauth_callback" => "about:blank",
     "oauth_signature" => "bYhud++kyPOu4KrRKwa+3YYHExs=",
     "oauth_timestamp" => "1562960453",
     "lti_message_type" => "basic-lti-launch-request",
     "resource_link_id" => "fa070692257fc1b67ce7461e18cecd418a5286d5",
     "oauth_consumer_key" => "key",
     "resource_link_title" => "#{Rails.application.class.parent.to_s} (dev)",
     "lis_result_sourcedid" => "318968-1588231-11790359-24013830-764e021613ae2e1f34bf45894cb5c18585459cbd",
     "ext_lti_assignment_id" => "46e09daf-bcdf-4bc0-bf30-1f15994d6346",
     "oauth_signature_method" => "HMAC-SHA1",
     "lis_outcome_service_url" => "https://canvas.instructure.com/api/lti/v1/tools/318968/grade_passback",
     "launch_presentation_locale" => "en",
     "tool_consumer_info_version" => "cloud",
     "tool_consumer_instance_guid" => "07adb3e60637ff02d9ea11c7c74f1ca921699bd7.canvas.instructure.com",
     "tool_consumer_instance_name" => "Free For Teacher",
     "ext_ims_lis_basic_outcome_url" =>
     "https://canvas.instructure.com/api/lti/v1/tools/318968/ext_grade_passback",
     "custom_canvas_assignment_title" => "#{Rails.application.class.parent.to_s} (dev)",
     "custom_canvas_enrollment_state" => "active",
     "launch_presentation_return_url" => "https://canvas.instructure.com/courses/1588231/assignments",
     "ext_outcomes_tool_placement_url" =>
     "https://canvas.instructure.com/api/lti/v1/turnitin/outcomes_placement/318968",
     "ext_outcome_data_values_accepted" => "url,text",
     "launch_presentation_document_target" => "iframe",
     "tool_consumer_instance_contact_email" => "notifications@instructure.com",
     "tool_consumer_info_product_family_code" => "canvas",
     "ext_outcome_result_total_score_accepted" => "true",
     "custom_canvas_assignment_points_possible" => "0",
     "ext_outcome_submission_submitted_at_accepted" => "true" },
)
puts "Add Student Launch"
