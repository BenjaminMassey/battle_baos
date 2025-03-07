extends VFlowContainer

func message(text: String):
	var log_message = Label.new();
	log_message.text = text;
	var message_tween = get_tree().create_tween();
	message_tween.tween_property(log_message, "modulate:a", 0, 1).set_delay(2);
	message_tween.tween_callback(log_message.queue_free);
	add_child(log_message);
	print(text);
