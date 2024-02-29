use godot::{
    engine::{
        AnimatedSprite2D, Area2D, AudioStreamPlayer2D, CharacterBody2D, IArea2D, ICharacterBody2D,
        ProjectSettings,
    },
    prelude::{utilities::move_toward, *},
};

struct Entry;

#[gdextension]
unsafe impl ExtensionLibrary for Entry {}

#[derive(GodotClass)]
#[class(base = CharacterBody2D)]
struct Player {
    // Normal properties
    speed: f64,
    gravity: f64,
    // Jump properties
    jump_velocity: f64,
    #[var]
    air_jumps: u16,
    air_jumps_count: u16,
    jumps_multiplier: f64,
    // Extra properties
    spawn_location: Option<Vector2>,
    sprite: Option<Gd<AnimatedSprite2D>>,
    audio: Option<Gd<AudioStreamPlayer2D>>,
    #[base]
    base: Base<CharacterBody2D>,
}

#[godot_api]
impl ICharacterBody2D for Player {
    fn init(base: Base<CharacterBody2D>) -> Self {
        Player {
            base,
            speed: 300.0,
            jump_velocity: -400.0,
            air_jumps: 2,
            air_jumps_count: 0,
            jumps_multiplier: 0.8,
            spawn_location: None,
            sprite: None,
            audio: None,
            gravity: ProjectSettings::singleton()
                .get_setting(GString::from("physics/2d/default_gravity"))
                .to::<f64>(),
        }
    }

    fn ready(&mut self) {
        let position = self.base().get_position();
        self.spawn_location = Some(position);

        let sprite = self
            .base()
            .get_node_as::<AnimatedSprite2D>(NodePath::from("AnimatedSprite2D"));

        self.sprite = Some(sprite);

        let audio = self
            .base()
            .get_node_as::<AudioStreamPlayer2D>(NodePath::from("AudioStreamPlayer2D"));

        self.audio = Some(audio);
    }

    fn physics_process(&mut self, delta: f64) {
        let input = Input::singleton();
        let mut sprite = self.sprite();
        let mut audio = self.audio();

        let mut velocity = self.base().get_velocity();
        let on_floor = self.base().is_on_floor();

        let solid_ground = match (
            on_floor,
            input.is_action_just_pressed(StringName::from("ui_up")),
        ) {
            (true, true) => {
                velocity.y = self.jump_velocity as f32;

                audio.play();
                true
            }
            (true, false) => {
                velocity.y = 0.0;

                self.air_jumps_count = 0;
                true
            }
            (false, true) if self.air_jumps_count < self.air_jumps => {
                let multiplier = self.jumps_multiplier.powi(self.air_jumps_count as i32 + 1);
                velocity.y = (self.jump_velocity * multiplier) as f32;

                self.air_jumps_count += 1;
                audio.play();
                true
            }
            (false, _) => {
                velocity.y += (self.gravity * delta) as f32;

                false
            }
        };

        let direction = input.get_axis(StringName::from("ui_left"), StringName::from("ui_right"));
        match (!direction.is_zero_approx(), solid_ground) {
            (true, true) => {
                velocity.x = (direction as f64 * self.speed) as f32;
                sprite.set_flip_h(direction.is_sign_negative());

                if on_floor {
                    sprite.set_animation(StringName::from("walk"));
                }
            }
            (false, true) => {
                velocity.x = move_toward(velocity.x as f64, 0.0, self.speed * delta) as f32;

                if on_floor {
                    sprite.set_animation(StringName::from("stand"));
                }
            }
            (_, false) => {
                velocity.x = move_toward(velocity.x as f64, 0.0, 0.05 * self.speed * delta) as f32;
                sprite.set_animation(StringName::from("jump"));
            }
        }

        sprite.play();
        self.base_mut().set_velocity(velocity);
        self.base_mut().move_and_slide();
    }
}

#[godot_api]
impl Player {
    fn spawn_location(&self) -> Vector2 {
        self.spawn_location.unwrap()
    }

    fn sprite(&self) -> Gd<AnimatedSprite2D> {
        self.sprite.as_ref().map(Clone::clone).unwrap()
    }

    fn audio(&self) -> Gd<AudioStreamPlayer2D> {
        self.audio.as_ref().map(Clone::clone).unwrap()
    }

    #[func]
    pub fn respawn(&mut self) {
        let position = self.spawn_location();
        self.base_mut().set_position(position);
    }

    #[func]
    pub fn get_spawn_location(&self) -> Vector2 {
        self.spawn_location()
    }

    #[func]
    pub fn set_spawn_location(&mut self, position: Vector2) {
        self.spawn_location = Some(position);
    }
}

#[derive(GodotClass)]
#[class(base = Area2D)]
struct Coin {
    #[var(get, set)]
    collected: bool,
    #[base]
    base: Base<Area2D>,
}

#[godot_api]
impl IArea2D for Coin {
    fn init(base: Base<Area2D>) -> Self {
        Coin {
            collected: false,
            base,
        }
    }

    fn ready(&mut self) {
        self.base_mut().set_monitoring(true);
    }
}
