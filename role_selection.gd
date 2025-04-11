# role_selection.gd
   extends CanvasLayer
   
   signal role_selected(role_name)
   
   func _on_detective_pressed():
       role_selected.emit("detective")
   
   func _on_police_pressed():
       role_selected.emit("police")
   
   func _on_journalist_pressed():
       role_selected.emit("journalist")
