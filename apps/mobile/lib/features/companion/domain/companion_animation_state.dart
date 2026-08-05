/// Visual/behavioral states the companion avatar can be rendered in.
/// A polished placeholder vector avatar interprets each state below;
/// a future 3D/animated asset pipeline can implement the same enum.
enum CompanionAnimationState {
  idle,
  greeting,
  listening,
  thinking,
  talking,
  celebrating,
  docked,
  hidden,
  chibi,
}
