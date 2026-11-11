extends GdUnitTestSuite


func test_scenery_moves_without_resetting_on_layout_change() -> void:
	var runner := scene_runner("res://scenes/main/game.tscn")
	await runner.simulate_frames(3)
	var world := runner.scene().find_child("PaperBackground") as Control
	world.set_process(false)
	var cloud := world.find_children("cloud_*", "TextureRect", true, false)[0] as Control
	var tree := world.find_children("pine_*", "TextureRect", true, false)[0] as Control
	var before := cloud.position
	var tree_angle := tree.rotation
	if world.has_method("_process"):
		world.call("_process", 2.0)
	assert_that(cloud.position.distance_to(before)).is_greater(0.01)
	assert_that(absf(tree.rotation - tree_angle)).is_greater(0.0001)
	var sails := world.find_child("WindmillSails", true, false) as Node2D
	assert_that(sails).is_not_null()
	if sails:
		var angle := sails.rotation
		world.call("_process", 1.0)
		assert_that(absf(sails.rotation - angle)).is_greater(0.01)
		var phase := sails.rotation
		world.call("refresh_layout")
		sails = world.find_child("WindmillSails", true, false) as Node2D
		assert_that(absf(sails.rotation - phase)).is_less(0.001)
	var details := world.find_child("LivingDetails", true, false)
	assert_that(details).is_not_null()
