import LevelCounterComponent from './level_counter.component';

/**
 * Level counter that can be put in a list. Destructures initdata and update data from the values given by list().
 */
class ListableLevelCountercomponent extends LevelCounterComponent {
  constructor([el_type, prefix, new_xp, recent_xp]) {
    super(el_type, prefix, new_xp, recent_xp);
  }

  update({name, xp, recent_xp}) {
    super.update(xp, recent_xp, name);
  }
}

export default ListableLevelCountercomponent;
