use crate::knight::Knight;
use godot::{
    engine::{AnimatedSprite2D, CharacterBody2D, ICharacterBody2D},
    prelude::*,
};

#[derive(GodotClass)]
#[class(base = CharacterBody2D)]
pub struct Goblin {
    #[var(get, set)]
    pub health: i32,
    #[var(get, set)]
    pub speed: f64,
    #[var(get = sprite)]
    sprite: Option<Gd<AnimatedSprite2D>>,
    #[var(get = knight)]
    knight: Option<Gd<Knight>>,
    base: Base<CharacterBody2D>,
}

#[godot_api]
impl Goblin {
    #[func]
    pub fn sprite(&self) -> Gd<AnimatedSprite2D> {
        self.sprite.as_ref().map(Gd::clone).unwrap()
    }

    #[func]
    pub fn knight(&self) -> Gd<Knight> {
        self.knight.as_ref().map(Gd::clone).unwrap()
    }
}

#[godot_api]
impl ICharacterBody2D for Goblin {
    fn init(base: Base<CharacterBody2D>) -> Self {
        Goblin {
            health: 350,
            speed: 5_000.0,
            sprite: None,
            knight: None,
            base,
        }
    }

    fn ready(&mut self) {
        let sprite = self
            .base()
            .get_node_as::<AnimatedSprite2D>("AnimatedSprite2D");

        let knight = self
            .base()
            .get_tree()
            .expect("`Goblin` should exist in the tree")
            .get_current_scene()
            .expect("`Goblin` should be in the current scene")
            .get_node_as::<Knight>("Knight");

        self.sprite = Some(sprite);
        self.knight = Some(knight);
    }

    fn physics_process(&mut self, delta: f64) {
        let target = self.knight().get_position();
        let current = self.base().get_position();

        self.base_mut()
            .set_z_index(if target.y < current.y { 1 } else { -1 });

        let distance = target - current;

        const G_RADIUS: f32 = 16.0;
        const K_RADIUS: f32 = 16.0;

        let direction = if distance.length() <= G_RADIUS + K_RADIUS + 4.0 {
            Vector2 { x: 0.0, y: 0.0 }
        } else {
            distance.normalized()
        };

        if !direction.x.is_zero_approx() {
            self.sprite().set_flip_h(direction.x.is_sign_negative());
        }

        if !direction.is_zero_approx() {
            let velocity = (self.speed * delta) as f32 * direction;
            self.base_mut().set_velocity(velocity);
            self.base_mut().move_and_slide();
            self.sprite().set_animation(StringName::from("Run"));
        } else {
            self.sprite().set_animation(StringName::from("Idle"));
        }

        self.sprite().play();
    }
}
