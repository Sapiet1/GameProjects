use godot::prelude::*;

pub struct Entry;

#[gdextension]
unsafe impl ExtensionLibrary for Entry {}

pub mod goblin;
pub mod knight;
