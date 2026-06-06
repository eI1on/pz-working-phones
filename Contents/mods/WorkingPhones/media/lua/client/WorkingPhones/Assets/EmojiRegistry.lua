local EmojiRegistry = {}

local Assets = require("WorkingPhones/Assets/PhoneAssets")

local ROOT = Assets.MESSAGE_EMOJIS

local CATEGORIES = {
	{
		id = "smileys_people",
		labelKey = "EmojiSmileys",
		icon = "grinning.png",
		files = {
			"+1.png", "-1.png", "100.png", "adult.png", "alien.png", "angel.png", "anger.png", "angry.png",
			"anguished.png", "astonished.png", "baby.png", "bald_man.png", "bald_woman.png", "bath.png",
			"bearded_person.png", "bicyclist.png",
			"black_heart.png", "blond-haired-man.png", "blond-haired-woman.png", "blue_heart.png", "blush.png",
			"bone.png", "boom.png", "bow.png",
			"boy.png", "brain.png", "breast-feeding.png", "bride_with_veil.png", "broken_heart.png", "brown_heart.png",
			"bust_in_silhouette.png", "busts_in_silhouette.png",
			"call_me_hand.png", "child.png", "clap.png", "clown_face.png", "cold_face.png", "cold_sweat.png",
			"confounded.png", "confused.png",
			"construction_worker.png", "cop.png", "couple_with_heart.png", "couplekiss.png", "crossed_fingers.png",
			"cry.png", "crying_cat_face.png", "cupid.png",
			"curly_haired_man.png", "curly_haired_woman.png", "dancer.png", "dancers.png", "dash.png", "deaf_man.png",
			"deaf_person.png", "deaf_woman.png",
			"disappointed.png", "disappointed_relieved.png", "dizzy.png", "dizzy_face.png", "drooling_face.png",
			"ear.png", "ear_with_hearing_aid.png", "elf.png",
			"exploding_head.png", "expressionless.png", "eye-in-speech-bubble.png", "eye.png", "eyes.png",
			"face_palm.png", "face_vomiting.png", "face_with_cowboy_hat.png",
			"face_with_hand_over_mouth.png", "face_with_head_bandage.png", "face_with_monocle.png",
			"face_with_raised_eyebrow.png", "face_with_rolling_eyes.png", "face_with_symbols_on_mouth.png",
			"face_with_thermometer.png", "facepunch.png",
			"fairy.png", "family.png", "fearful.png", "female-artist.png", "female-astronaut.png",
			"female-construction-worker.png", "female-cook.png", "female-detective.png",
			"female-doctor.png", "female-factory-worker.png", "female-farmer.png", "female-firefighter.png",
			"female-guard.png", "female-judge.png", "female-mechanic.png", "female-office-worker.png",
			"female-pilot.png", "female-police-officer.png", "female-scientist.png", "female-singer.png",
			"female-student.png", "female-teacher.png", "female-technologist.png", "female_elf.png",
			"female_fairy.png", "female_genie.png", "female_mage.png", "female_superhero.png", "female_supervillain.png",
			"female_vampire.png", "female_zombie.png", "fencer.png",
			"fist.png", "flushed.png", "foot.png", "footprints.png", "frowning.png", "genie.png", "ghost.png",
			"gift_heart.png",
			"girl.png", "golfer.png", "green_heart.png", "grimacing.png", "grin.png", "grinning.png", "guardsman.png",
			"haircut.png",
			"hand.png", "handball.png", "handshake.png", "hankey.png", "hear_no_evil.png", "heart.png",
			"heart_decoration.png", "heart_eyes.png",
			"heart_eyes_cat.png", "heartbeat.png", "heartpulse.png", "heavy_heart_exclamation_mark_ornament.png",
			"hole.png", "horse_racing.png", "hot_face.png", "hugging_face.png",
			"hushed.png", "i_love_you_hand_sign.png", "imp.png", "information_desk_person.png", "innocent.png",
			"japanese_goblin.png", "japanese_ogre.png", "joy.png",
			"joy_cat.png", "juggling.png", "kiss.png", "kissing.png", "kissing_cat.png", "kissing_closed_eyes.png",
			"kissing_heart.png", "kissing_smiling_eyes.png",
			"kneeling_person.png", "laughing.png", "left-facing_fist.png", "left_speech_bubble.png", "leg.png",
			"lips.png", "love_letter.png", "lying_face.png",
			"mage.png", "male-artist.png", "male-astronaut.png", "male-construction-worker.png", "male-cook.png",
			"male-detective.png", "male-doctor.png", "male-factory-worker.png",
			"male-farmer.png", "male-firefighter.png", "male-guard.png", "male-judge.png", "male-mechanic.png",
			"male-office-worker.png", "male-pilot.png", "male-police-officer.png",
			"male-scientist.png", "male-singer.png", "male-student.png", "male-teacher.png", "male-technologist.png",
			"male_elf.png", "male_fairy.png", "male_genie.png",
			"male_mage.png", "male_superhero.png", "male_supervillain.png", "male_vampire.png", "male_zombie.png",
			"man-biking.png", "man-bouncing-ball.png", "man-bowing.png",
			"man-boy-boy.png", "man-boy.png", "man-cartwheeling.png", "man-facepalming.png", "man-frowning.png",
			"man-gesturing-no.png", "man-gesturing-ok.png", "man-getting-haircut.png",
			"man-getting-massage.png", "man-girl-boy.png", "man-girl-girl.png", "man-girl.png", "man-golfing.png",
			"man-heart-man.png", "man-juggling.png", "man-kiss-man.png",
			"man-lifting-weights.png", "man-man-boy-boy.png", "man-man-boy.png", "man-man-girl-boy.png",
			"man-man-girl-girl.png", "man-man-girl.png", "man-mountain-biking.png", "man-playing-handball.png",
			"man-playing-water-polo.png", "man-pouting.png", "man-raising-hand.png", "man-rowing-boat.png",
			"man-running.png", "man-shrugging.png", "man-surfing.png", "man-swimming.png",
			"man-tipping-hand.png", "man-walking.png", "man-wearing-turban.png", "man-woman-boy-boy.png",
			"man-woman-boy.png", "man-woman-girl-boy.png", "man-woman-girl-girl.png", "man-woman-girl.png",
			"man-wrestling.png", "man.png", "man_and_woman_holding_hands.png", "man_climbing.png", "man_dancing.png",
			"man_in_business_suit_levitating.png", "man_in_lotus_position.png", "man_in_manual_wheelchair.png",
			"man_in_motorized_wheelchair.png", "man_in_steamy_room.png", "man_kneeling.png", "man_standing.png",
			"man_with_gua_pi_mao.png", "man_with_probing_cane.png", "man_with_turban.png", "mask.png",
			"massage.png", "mechanical_arm.png", "mechanical_leg.png", "men-with-bunny-ears-partying.png", "mermaid.png",
			"merman.png", "merperson.png", "middle_finger.png",
			"money_mouth_face.png", "mountain_bicyclist.png", "mrs_claus.png", "muscle.png", "nail_care.png",
			"nauseated_face.png", "nerd_face.png", "neutral_face.png",
			"no_good.png", "no_mouth.png", "nose.png", "ok_hand.png", "ok_woman.png", "older_adult.png", "older_man.png",
			"older_woman.png",
			"open_hands.png", "open_mouth.png", "orange_heart.png", "palms_up_together.png", "partying_face.png",
			"pensive.png", "people_holding_hands.png", "persevere.png",
			"person_climbing.png", "person_doing_cartwheel.png", "person_frowning.png", "person_in_lotus_position.png",
			"person_in_steamy_room.png", "person_in_tuxedo.png", "person_with_ball.png", "person_with_blond_hair.png",
			"person_with_headscarf.png", "person_with_pouting_face.png", "pinching_hand.png", "pleading_face.png",
			"point_down.png", "point_left.png", "point_right.png", "point_up.png",
			"point_up_2.png", "pouting_cat.png", "pray.png", "pregnant_woman.png", "prince.png", "princess.png",
			"purple_heart.png", "rage.png",
			"raised_back_of_hand.png", "raised_hand_with_fingers_splayed.png", "raised_hands.png", "raising_hand.png",
			"red_haired_man.png", "red_haired_woman.png", "relaxed.png", "relieved.png",
			"revolving_hearts.png", "right-facing_fist.png", "right_anger_bubble.png", "robot_face.png",
			"rolling_on_the_floor_laughing.png", "rowboat.png", "runner.png", "santa.png",
			"scream.png", "scream_cat.png", "see_no_evil.png", "selfie.png", "shrug.png", "shushing_face.png",
			"skier.png", "skull.png",
			"skull_and_crossbones.png", "sleeping.png", "sleeping_accommodation.png", "sleepy.png", "sleuth_or_spy.png",
			"slightly_frowning_face.png", "slightly_smiling_face.png", "smile.png",
			"smile_cat.png", "smiley.png", "smiley_cat.png", "smiling_face_with_3_hearts.png", "smiling_imp.png",
			"smirk.png", "smirk_cat.png", "sneezing_face.png",
			"snowboarder.png", "sob.png", "space_invader.png", "sparkling_heart.png", "speak_no_evil.png",
			"speaking_head_in_silhouette.png", "speech_balloon.png", "spock-hand.png",
			"standing_person.png", "star-struck.png", "stuck_out_tongue.png", "stuck_out_tongue_closed_eyes.png",
			"stuck_out_tongue_winking_eye.png", "sunglasses.png", "superhero.png", "supervillain.png",
			"surfer.png", "sweat.png", "sweat_drops.png", "sweat_smile.png", "swimmer.png", "the_horns.png",
			"thinking_face.png", "thought_balloon.png",
			"tired_face.png", "tongue.png", "tooth.png", "triumph.png", "two_hearts.png", "two_men_holding_hands.png",
			"two_women_holding_hands.png", "unamused.png",
			"upside_down_face.png", "v.png", "vampire.png", "walking.png", "water_polo.png", "wave.png", "weary.png",
			"weight_lifter.png",
			"white_frowning_face.png", "white_haired_man.png", "white_haired_woman.png", "white_heart.png", "wink.png",
			"woman-biking.png", "woman-bouncing-ball.png", "woman-bowing.png",
			"woman-boy-boy.png", "woman-boy.png", "woman-cartwheeling.png", "woman-facepalming.png", "woman-frowning.png",
			"woman-gesturing-no.png", "woman-gesturing-ok.png", "woman-getting-haircut.png",
			"woman-getting-massage.png", "woman-girl-boy.png", "woman-girl-girl.png", "woman-girl.png",
			"woman-golfing.png", "woman-heart-man.png", "woman-heart-woman.png", "woman-juggling.png",
			"woman-kiss-man.png", "woman-kiss-woman.png", "woman-lifting-weights.png", "woman-mountain-biking.png",
			"woman-playing-handball.png", "woman-playing-water-polo.png", "woman-pouting.png", "woman-raising-hand.png",
			"woman-rowing-boat.png", "woman-running.png", "woman-shrugging.png", "woman-surfing.png",
			"woman-swimming.png", "woman-tipping-hand.png", "woman-walking.png", "woman-wearing-turban.png",
			"woman-woman-boy-boy.png", "woman-woman-boy.png", "woman-woman-girl-boy.png", "woman-woman-girl-girl.png",
			"woman-woman-girl.png", "woman-wrestling.png", "woman.png", "woman_climbing.png",
			"woman_in_lotus_position.png", "woman_in_manual_wheelchair.png", "woman_in_motorized_wheelchair.png",
			"woman_in_steamy_room.png", "woman_kneeling.png", "woman_standing.png", "woman_with_probing_cane.png",
			"women-with-bunny-ears-partying.png",
			"woozy_face.png", "worried.png", "wrestlers.png", "writing_hand.png", "yawning_face.png", "yellow_heart.png",
			"yum.png", "zany_face.png",
			"zipper_mouth_face.png", "zombie.png", "zzz.png",
		},
	},
	{
		id = "animals_nature",
		labelKey = "EmojiNature",
		icon = "blossom.png",
		files = {
			"ant.png", "baby_chick.png", "badger.png", "bat.png", "bear.png", "bee.png", "bird.png", "blossom.png",
			"blowfish.png", "boar.png", "bouquet.png", "bug.png", "butterfly.png", "cactus.png", "camel.png", "cat.png",
			"cat2.png", "cherry_blossom.png", "chicken.png", "chipmunk.png", "cow.png", "cow2.png", "cricket.png",
			"crocodile.png",
			"deciduous_tree.png", "deer.png", "dog.png", "dog2.png", "dolphin.png", "dove_of_peace.png", "dragon.png",
			"dragon_face.png",
			"dromedary_camel.png", "duck.png", "eagle.png", "ear_of_rice.png", "elephant.png", "evergreen_tree.png",
			"fallen_leaf.png", "feet.png",
			"fish.png", "flamingo.png", "four_leaf_clover.png", "fox_face.png", "frog.png", "giraffe_face.png",
			"goat.png", "gorilla.png",
			"guide_dog.png", "hamster.png", "hatched_chick.png", "hatching_chick.png", "hedgehog.png", "herb.png",
			"hibiscus.png", "hippopotamus.png",
			"horse.png", "kangaroo.png", "koala.png", "ladybug.png", "leaves.png", "leopard.png", "lion_face.png",
			"lizard.png",
			"llama.png", "maple_leaf.png", "microbe.png", "monkey.png", "monkey_face.png", "mosquito.png", "mouse.png",
			"mouse2.png",
			"mushroom.png", "octopus.png", "orangutan.png", "otter.png", "owl.png", "ox.png", "palm_tree.png",
			"panda_face.png",
			"parrot.png", "peacock.png", "penguin.png", "pig.png", "pig2.png", "pig_nose.png", "poodle.png", "rabbit.png",
			"rabbit2.png", "raccoon.png", "racehorse.png", "ram.png", "rat.png", "rhinoceros.png", "rooster.png",
			"rose.png",
			"rosette.png", "sauropod.png", "scorpion.png", "seedling.png", "service_dog.png", "shamrock.png", "shark.png",
			"sheep.png",
			"shell.png", "skunk.png", "sloth.png", "snail.png", "snake.png", "spider.png", "spider_web.png",
			"sunflower.png",
			"swan.png", "t-rex.png", "tiger.png", "tiger2.png", "tropical_fish.png", "tulip.png", "turkey.png",
			"turtle.png",
			"unicorn_face.png", "water_buffalo.png", "whale.png", "whale2.png", "white_flower.png", "wilted_flower.png",
			"wolf.png", "zebra_face.png",
		},
	},
	{
		id = "food_drink",
		labelKey = "EmojiFood",
		icon = "apple.png",
		files = {
			"amphora.png", "apple.png", "avocado.png", "baby_bottle.png", "bacon.png", "bagel.png", "baguette_bread.png",
			"banana.png",
			"beer.png", "beers.png", "bento.png", "beverage_box.png", "birthday.png", "bowl_with_spoon.png", "bread.png",
			"broccoli.png",
			"burrito.png", "butter.png", "cake.png", "candy.png", "canned_food.png", "carrot.png", "champagne.png",
			"cheese_wedge.png",
			"cherries.png", "chestnut.png", "chocolate_bar.png", "chopsticks.png", "clinking_glasses.png", "cocktail.png",
			"coconut.png", "coffee.png",
			"cookie.png", "corn.png", "crab.png", "croissant.png", "cucumber.png", "cup_with_straw.png", "cupcake.png",
			"curry.png",
			"custard.png", "cut_of_meat.png", "dango.png", "doughnut.png", "dumpling.png", "egg.png", "eggplant.png",
			"falafel.png",
			"fish_cake.png", "fork_and_knife.png", "fortune_cookie.png", "fried_egg.png", "fried_shrimp.png", "fries.png",
			"garlic.png", "glass_of_milk.png",
			"grapes.png", "green_apple.png", "green_salad.png", "hamburger.png", "hocho.png", "honey_pot.png",
			"hot_pepper.png", "hotdog.png",
			"ice_cream.png", "ice_cube.png", "icecream.png", "kiwifruit.png", "knife_fork_plate.png", "leafy_green.png",
			"lemon.png", "lobster.png",
			"lollipop.png", "mango.png", "mate_drink.png", "meat_on_bone.png", "melon.png", "moon_cake.png", "oden.png",
			"onion.png",
			"oyster.png", "pancakes.png", "peach.png", "peanuts.png", "pear.png", "pie.png", "pineapple.png", "pizza.png",
			"popcorn.png", "potato.png", "poultry_leg.png", "pretzel.png", "ramen.png", "rice.png", "rice_ball.png",
			"rice_cracker.png",
			"sake.png", "salt.png", "sandwich.png", "shallow_pan_of_food.png", "shaved_ice.png", "shrimp.png",
			"spaghetti.png", "spoon.png",
			"squid.png", "stew.png", "strawberry.png", "stuffed_flatbread.png", "sushi.png", "sweet_potato.png",
			"taco.png", "takeout_box.png",
			"tangerine.png", "tea.png", "tomato.png", "tropical_drink.png", "tumbler_glass.png", "waffle.png",
			"watermelon.png", "wine_glass.png",
		},
	},
	{
		id = "activity",
		labelKey = "EmojiFun",
		icon = "chess_pawn.png",
		files = {
			"8ball.png", "admission_tickets.png", "art.png", "badminton_racquet_and_shuttlecock.png", "balloon.png",
			"bamboo.png", "baseball.png", "basketball.png",
			"black_joker.png", "bowling.png", "boxing_glove.png", "chess_pawn.png", "christmas_tree.png", "clubs.png",
			"confetti_ball.png", "cricket_bat_and_ball.png",
			"crystal_ball.png", "curling_stone.png", "dart.png", "diamonds.png", "diving_mask.png", "dolls.png",
			"field_hockey_stick_and_ball.png", "firecracker.png",
			"fireworks.png", "first_place_medal.png", "fishing_pole_and_fish.png", "flags.png",
			"flower_playing_cards.png", "flying_disc.png", "football.png", "frame_with_picture.png",
			"game_die.png", "gift.png", "goal_net.png", "golf.png", "gun.png", "hearts.png",
			"ice_hockey_stick_and_puck.png", "ice_skate.png",
			"jack_o_lantern.png", "jigsaw.png", "joystick.png", "kite.png", "lacrosse.png", "mahjong.png",
			"martial_arts_uniform.png", "medal.png",
			"performing_arts.png", "red_envelope.png", "reminder_ribbon.png", "ribbon.png", "rice_scene.png",
			"rugby_football.png", "running_shirt_with_sash.png", "second_place_medal.png",
			"ski.png", "sled.png", "slot_machine.png", "soccer.png", "softball.png", "spades.png", "sparkler.png",
			"sparkles.png",
			"sports_medal.png", "table_tennis_paddle_and_ball.png", "tada.png", "tanabata_tree.png", "teddy_bear.png",
			"tennis.png", "third_place_medal.png", "thread.png",
			"ticket.png", "trophy.png", "video_game.png", "volleyball.png", "wind_chime.png", "yarn.png", "yo-yo.png",
		},
	},
	{
		id = "travel_places",
		labelKey = "EmojiTravel",
		icon = "airplane.png",
		files = {
			"aerial_tramway.png", "airplane.png", "airplane_arriving.png", "airplane_departure.png", "alarm_clock.png",
			"ambulance.png", "anchor.png", "articulated_lorry.png",
			"auto_rickshaw.png", "bank.png", "barber.png", "barely_sunny.png", "beach_with_umbrella.png",
			"bellhop_bell.png", "bike.png", "blue_car.png",
			"boat.png", "bricks.png", "bridge_at_night.png", "building_construction.png", "bullettrain_front.png",
			"bullettrain_side.png", "bus.png", "busstop.png",
			"camping.png", "canoe.png", "car.png", "carousel_horse.png", "church.png", "circus_tent.png",
			"city_sunrise.png", "city_sunset.png",
			"cityscape.png", "classical_building.png", "clock1.png", "clock10.png", "clock1030.png", "clock11.png",
			"clock1130.png", "clock12.png",
			"clock1230.png", "clock130.png", "clock2.png", "clock230.png", "clock3.png", "clock330.png", "clock4.png",
			"clock430.png",
			"clock5.png", "clock530.png", "clock6.png", "clock630.png", "clock7.png", "clock730.png", "clock8.png",
			"clock830.png",
			"clock9.png", "clock930.png", "closed_umbrella.png", "cloud.png", "comet.png", "compass.png",
			"construction.png", "convenience_store.png",
			"crescent_moon.png", "cyclone.png", "department_store.png", "derelict_house_building.png", "desert.png",
			"desert_island.png", "droplet.png", "earth_africa.png",
			"earth_americas.png", "earth_asia.png", "european_castle.png", "european_post_office.png", "factory.png",
			"ferris_wheel.png", "ferry.png", "fire.png",
			"fire_engine.png", "first_quarter_moon.png", "first_quarter_moon_with_face.png", "flying_saucer.png",
			"fog.png", "foggy.png", "fountain.png", "fuelpump.png",
			"full_moon.png", "full_moon_with_face.png", "globe_with_meridians.png", "helicopter.png", "hindu_temple.png",
			"hospital.png", "hotel.png", "hotsprings.png",
			"hourglass.png", "hourglass_flowing_sand.png", "house.png", "house_buildings.png", "house_with_garden.png",
			"japan.png", "japanese_castle.png", "kaaba.png",
			"last_quarter_moon.png", "last_quarter_moon_with_face.png", "light_rail.png", "lightning.png",
			"love_hotel.png", "luggage.png", "mantelpiece_clock.png", "manual_wheelchair.png",
			"metro.png", "milky_way.png", "minibus.png", "monorail.png", "moon.png", "mosque.png", "mostly_sunny.png",
			"motor_boat.png",
			"motor_scooter.png", "motorized_wheelchair.png", "motorway.png", "mount_fuji.png", "mountain.png",
			"mountain_cableway.png", "mountain_railway.png", "national_park.png",
			"new_moon.png", "new_moon_with_face.png", "night_with_stars.png", "ocean.png", "octagonal_sign.png",
			"office.png", "oil_drum.png", "oncoming_automobile.png",
			"oncoming_bus.png", "oncoming_police_car.png", "oncoming_taxi.png", "parachute.png", "partly_sunny.png",
			"partly_sunny_rain.png", "passenger_ship.png", "police_car.png",
			"post_office.png", "racing_car.png", "racing_motorcycle.png", "railway_car.png", "railway_track.png",
			"rain_cloud.png", "rainbow.png", "ringed_planet.png",
			"rocket.png", "roller_coaster.png", "rotating_light.png", "satellite.png", "school.png", "scooter.png",
			"seat.png", "shinto_shrine.png",
			"ship.png", "skateboard.png", "small_airplane.png", "snow_capped_mountain.png", "snow_cloud.png",
			"snowflake.png", "snowman.png", "snowman_without_snow.png",
			"speedboat.png", "stadium.png", "star.png", "star2.png", "stars.png", "station.png", "statue_of_liberty.png",
			"steam_locomotive.png",
			"stopwatch.png", "sun_with_face.png", "sunny.png", "sunrise.png", "sunrise_over_mountains.png",
			"suspension_railway.png", "synagogue.png", "taxi.png",
			"tent.png", "thermometer.png", "thunder_cloud_and_rain.png", "timer_clock.png", "tokyo_tower.png",
			"tornado.png", "tractor.png", "traffic_light.png",
			"train.png", "train2.png", "tram.png", "trolleybus.png", "truck.png", "umbrella.png",
			"umbrella_on_ground.png", "umbrella_with_rain_drops.png",
			"vertical_traffic_light.png", "volcano.png", "waning_crescent_moon.png", "waning_gibbous_moon.png",
			"watch.png", "waxing_crescent_moon.png", "wedding.png", "wind_blowing_face.png",
			"world_map.png", "zap.png",
		},
	},
	{
		id = "objects",
		labelKey = "EmojiItems",
		icon = "bell.png",
		files = {
			"athletic_shoe.png", "axe.png", "ballet_shoes.png", "banjo.png", "bar_chart.png", "battery.png", "bell.png",
			"bikini.png",
			"billed_cap.png", "bomb.png", "boot.png", "bow_and_arrow.png", "briefs.png", "calendar.png", "calling.png",
			"card_file_box.png",
			"card_index.png", "chart_with_downwards_trend.png", "chart_with_upwards_trend.png", "clipboard.png",
			"closed_lock_with_key.png", "coat.png", "compression.png", "computer.png",
			"crossed_swords.png", "crown.png", "dagger_knife.png", "dark_sunglasses.png", "date.png",
			"desktop_computer.png", "dress.png", "drum_with_drumsticks.png",
			"electric_plug.png", "eyeglasses.png", "fax.png", "file_cabinet.png", "floppy_disk.png", "gear.png",
			"gem.png", "gloves.png",
			"goggles.png", "hammer.png", "hammer_and_pick.png", "hammer_and_wrench.png", "handbag.png",
			"helmet_with_white_cross.png", "high_heel.png", "hiking_boot.png",
			"iphone.png", "jeans.png", "key.png", "keyboard.png", "kimono.png", "lab_coat.png", "linked_paperclips.png",
			"lipstick.png",
			"lock.png", "lock_with_ink_pen.png", "loud_sound.png", "loudspeaker.png", "mans_shoe.png", "mega.png",
			"minidisc.png", "mortar_board.png",
			"musical_keyboard.png", "musical_score.png", "mute.png", "necktie.png", "no_bell.png", "nut_and_bolt.png",
			"old_key.png", "one-piece_swimsuit.png",
			"pager.png", "paperclip.png", "phone.png", "pick.png", "postal_horn.png", "pouch.png", "prayer_beads.png",
			"printer.png",
			"purse.png", "pushpin.png", "ring.png", "round_pushpin.png", "safety_vest.png", "sandal.png", "sari.png",
			"scales.png",
			"scarf.png", "school_satchel.png", "scissors.png", "shield.png", "shirt.png", "shopping_bags.png",
			"shorts.png", "socks.png",
			"sound.png", "speaker.png", "spiral_calendar_pad.png", "spiral_note_pad.png", "straight_ruler.png",
			"telephone_receiver.png", "three_button_mouse.png", "tophat.png",
			"trackball.png", "triangular_ruler.png", "trumpet.png", "unlock.png", "violin.png", "wastebasket.png",
			"womans_clothes.png", "womans_flat_shoe.png",
			"womans_hat.png", "wrench.png",
		},
	},
	{
		id = "symbols",
		labelKey = "EmojiSigns",
		icon = "1234.png",
		files = {
			"1234.png", "a.png", "ab.png", "abc.png", "abcd.png", "accept.png", "b.png", "baggage_claim.png",
			"ballot_box_with_check.png", "bangbang.png", "beginner.png", "black_circle.png", "black_large_square.png",
			"black_medium_small_square.png", "black_medium_square.png", "black_small_square.png",
			"black_square_button.png", "capital_abcd.png", "cl.png", "congratulations.png", "cool.png", "copyright.png",
			"curly_loop.png", "currency_exchange.png",
			"customs.png", "diamond_shape_with_a_dot_inside.png", "eight.png", "eight_pointed_black_star.png",
			"eight_spoked_asterisk.png", "exclamation.png", "five.png", "fleur_de_lis.png",
			"four.png", "free.png", "grey_exclamation.png", "grey_question.png", "hash.png", "heavy_check_mark.png",
			"heavy_division_sign.png", "heavy_dollar_sign.png",
			"heavy_minus_sign.png", "heavy_plus_sign.png", "id.png", "ideograph_advantage.png", "infinity.png",
			"information_source.png", "interrobang.png", "keycap_star.png",
			"keycap_ten.png", "koko.png", "large_blue_circle.png", "large_blue_diamond.png", "large_blue_square.png",
			"large_brown_circle.png", "large_brown_square.png", "large_green_circle.png",
			"large_green_square.png", "large_orange_circle.png", "large_orange_diamond.png", "large_orange_square.png",
			"large_purple_circle.png", "large_purple_square.png", "large_red_square.png", "large_yellow_circle.png",
			"large_yellow_square.png", "loop.png", "m.png", "medical_symbol.png", "name_badge.png",
			"negative_squared_cross_mark.png", "new.png", "ng.png",
			"nine.png", "o.png", "o2.png", "ok.png", "one.png", "parking.png", "part_alternation_mark.png",
			"passport_control.png",
			"question.png", "radio_button.png", "recycle.png", "red_circle.png", "registered.png", "sa.png", "secret.png",
			"seven.png",
			"six.png", "small_blue_diamond.png", "small_orange_diamond.png", "small_red_triangle.png",
			"small_red_triangle_down.png", "sos.png", "sparkle.png", "symbols.png",
			"three.png", "tm.png", "trident.png", "two.png", "u5272.png", "u5408.png", "u55b6.png", "u6307.png",
			"u6708.png", "u6709.png", "u6e80.png", "u7121.png", "u7533.png", "u7981.png", "u7a7a.png", "up.png",
			"vs.png", "wavy_dash.png", "white_check_mark.png", "white_circle.png", "white_large_square.png",
			"white_medium_small_square.png", "white_medium_square.png", "white_small_square.png",
			"white_square_button.png", "x.png", "zero.png",
		},
	},
	{
		id = "flags",
		labelKey = "EmojiFlags",
		icon = "checkered_flag.png",
		files = {
			"checkered_flag.png", "crossed_flags.png", "pirate_flag.png", "rainbow-flag.png",
			"triangular_flag_on_post.png", "waving_black_flag.png", "waving_white_flag.png",
		},
	},
}

function EmojiRegistry.categories()
	return CATEGORIES
end

function EmojiRegistry.path(categoryId, fileName)
	return ROOT .. tostring(categoryId or "") .. "/" .. tostring(fileName or "")
end

local LOOKUP

local function emojiName(fileName)
	local name = string.gsub(tostring(fileName or ""), "%.png$", "")
	name = string.lower(name)
	return string.gsub(name, "%-", "_")
end

local function buildLookup()
	if LOOKUP then return LOOKUP end
	LOOKUP = {}
	for c = 1, #CATEGORIES do
		local category = CATEGORIES[c]
		for f = 1, #category.files do
			local fileName = category.files[f]
			local normalized = emojiName(fileName)
			if not LOOKUP[normalized] then
				LOOKUP[normalized] = { category = category.id, name = string.gsub(fileName, "%.png$", ""), path =
				EmojiRegistry.path(category.id, fileName) }
			end
			local original = string.lower(string.gsub(fileName, "%.png$", ""))
			if not LOOKUP[original] then
				LOOKUP[original] = LOOKUP[normalized]
			end
		end
	end
	return LOOKUP
end

function EmojiRegistry.token(categoryId, fileName)
	return ":" .. emojiName(fileName) .. ":"
end

function EmojiRegistry.parseToken(token)
	local value = tostring(token or "")
	local name = string.match(value, "^:([%w_%+%-]+):$")
	if not name then return nil end
	local found = buildLookup()[string.lower(name)]
	if not found then return nil end
	return found
end

function EmojiRegistry.parts(text)
	local value = tostring(text or "")
	local parts = {}
	local pos = 1
	while pos <= #value do
		local startAt, endAt, name = string.find(value, ":([%w_%+%-]+):", pos)
		if not startAt or not endAt then
			table.insert(parts, { kind = "text", text = string.sub(value, pos) })
			break
		end
		if startAt > pos then
			table.insert(parts, { kind = "text", text = string.sub(value, pos, startAt - 1) })
		end
		local emoji = buildLookup()[string.lower(name)]
		if emoji then
			table.insert(parts, { kind = "emoji", category = emoji.category, name = emoji.name, path = emoji.path })
		else
			table.insert(parts, { kind = "text", text = string.sub(value, startAt, endAt) })
		end
		pos = endAt + 1
	end
	return parts
end

return EmojiRegistry
