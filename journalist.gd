class_name Journalist
extends RoleBase

@onready var camera = $Camera
@onready var recorder = $Recorder

func _ready():
    role_name = "journalist"
    move_speed = 5.5
    health = 80
    faction = "media"
    
    abilities = {
        "take_photo": {
            "enabled": true,
            "use": take_photo
        },
        "record_audio": {
            "enabled": true,
            "use": record_audio
        },
        "publish_story": {
            "enabled": true,
            "use": publish_story
        }
    }

func take_photo(target):
    if camera:
        var photo_info = camera.capture(target)
        if photo_info:
            add_to_inventory(photo_info)
            return true
    return false

func record_audio(target):
    if recorder and target.has_method("start_conversation"):
        var conversation = target.start_conversation()
        recorder.record(conversation)
        return true
    return false

func publish_story(story_data):
    var media_outlet = get_node("/root/Game/MediaSystem")
    if media_outlet:
        var impact = media_outlet.publish(story_data, reputation)
        update_reputation_from_story(impact)
        return true
    return false

func update_reputation_from_story(impact: Dictionary):
    for faction_name in impact:
        reputation[faction_name] += impact[faction_name]
