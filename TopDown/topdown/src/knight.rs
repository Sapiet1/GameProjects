use godot::{
    engine::{AnimatedSprite2D, Area2D, CharacterBody2D, ICharacterBody2D, ResourcePreloader},
    prelude::*,
};
use std::f32::consts::PI;

#[derive(GodotClass)]
#[class(base = CharacterBody2D)]
pub struct Knight {
    #[var(get, set)]
    pub health: i32,
    #[var(get, set)]
    pub speed: f64,
    #[var(get = sprite)]
    sprite: Option<Gd<AnimatedSprite2D>>,
    #[var(get = attacks)]
    attacks: Option<Gd<ResourcePreloader>>,
    attacking: bool,
    base: Base<CharacterBody2D>,
}

#[godot_api]
impl Knight {
    #[func]
    pub fn sprite(&self) -> Gd<AnimatedSprite2D> {
        self.sprite.as_ref().map(Gd::clone).unwrap()
    }

    #[func]
    pub fn attacks(&self) -> Gd<ResourcePreloader> {
        self.attacks.as_ref().map(Gd::clone).unwrap()
    }
}

#[godot_api]
impl ICharacterBody2D for Knight {
    fn init(base: Base<CharacterBody2D>) -> Self {
        Knight {
            health: 500,
            speed: 10_000.0,
            sprite: None,
            attacks: None,
            attacking: false,
            base,
        }
    }

    fn ready(&mut self) {
        let sprite = self
            .base()
            .get_node_as::<AnimatedSprite2D>("AnimatedSprite2D");

        let attacks = self
            .base()
            .get_node_as::<ResourcePreloader>("ResourcePreloader");

        self.sprite = Some(sprite);
        self.attacks = Some(attacks);
    }

    fn physics_process(&mut self, delta: f64) {
        if self.attacking {
            const ATTACK_FRAMES: i32 = 11;
            const ATTACK_DOWN_FRAMES: i32 = 11;
            const ATTACK_UP_FRAMES: i32 = 11;

            const S1_ATTACK: i32 = 3;
            const S2_ATTACK: i32 = 9;
            const S1_ATTACK_DOWN: i32 = 3;
            const S2_ATTACK_DOWN: i32 = 9;
            const S1_ATTACK_UP: i32 = 3;
            const S2_ATTACK_UP: i32 = 9;

            let animation = self.sprite().get_animation().to_string();
            let frame = self.sprite().get_frame();

            let load = |resource: &str| {
                let resource = self
                    .attacks()
                    .get_resource(StringName::from(resource))
                    .expect("expected resource not in `ResourcePreloader`")
                    .cast::<PackedScene>();

                resource
                    .instantiate()
                    .expect("unable to instantiate resource")
                    .cast::<Area2D>()
            };

            match (&animation[..], frame) {
                ("Attack", ATTACK_FRAMES)
                | ("AttackDown", ATTACK_DOWN_FRAMES)
                | ("AttackUp", ATTACK_UP_FRAMES) => self.attacking = false,
                ("Attack", S1_ATTACK | S2_ATTACK) if self.sprite().is_flipped_h() => {
                    let mut attack = load("attack");
                    attack.set_rotation(PI);
                    self.base_mut().add_child(attack.upcast::<Node>());
                }
                ("Attack", S1_ATTACK | S2_ATTACK) => {
                    let attack = load("attack");
                    self.base_mut().add_child(attack.upcast::<Node>());
                }
                ("AttackDown", S1_ATTACK_DOWN | S2_ATTACK_DOWN) => {
                    let attack = load("attack_vertical");
                    self.base_mut().add_child(attack.upcast::<Node>());
                }
                ("AttackUp", S1_ATTACK_UP | S2_ATTACK_UP) => {
                    let mut attack = load("attack_vertical");
                    attack.set_rotation(PI);
                    self.base_mut().add_child(attack.upcast::<Node>());
                }
                _ => (),
            }

            return;
        }

        let attack = Input::singleton().is_action_just_pressed(StringName::from("ui_accept"));
        let direction = Input::singleton().get_vector(
            StringName::from("ui_left"),
            StringName::from("ui_right"),
            StringName::from("ui_up"),
            StringName::from("ui_down"),
        );

        if !direction.x.is_zero_approx() {
            self.sprite().set_flip_h(direction.x.is_sign_negative());
        }

        match (!direction.is_zero_approx(), attack) {
            // If moving without requesting for an attack.
            (true, false) => {
                let velocity = (self.speed * delta) as f32 * direction;
                self.base_mut().set_velocity(velocity);
                self.base_mut().move_and_slide();
                self.sprite().set_animation(StringName::from("Run"));
            }
            // If moving while requesting for an attack.
            (true, true) => match (!direction.x.is_zero_approx(), !direction.y.is_zero_approx()) {
                // If there is movement horizontally or if there is no movement vertically.
                (true, _) | (_, false) => {
                    self.sprite().set_animation(StringName::from("Attack"));
                    self.attacking = true;
                }
                // If there is no movement horizontally.
                (false, true) => {
                    if direction.y.is_sign_negative() {
                        self.sprite().set_animation(StringName::from("AttackUp"));
                    } else {
                        self.sprite().set_animation(StringName::from("AttackDown"));
                    }

                    self.attacking = true;
                }
            },
            // If not moving without requesting for an attack.
            (false, false) => self.sprite().set_animation(StringName::from("Idle")),
            // If not moving and requesting for an attack.
            (false, true) => {
                self.sprite().set_animation(StringName::from("Attack"));
                self.attacking = true;
            }
        }

        self.sprite().play();
    }
}
