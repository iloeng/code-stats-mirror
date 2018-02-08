import {el} from 'redom';

/**
 * Component that is shown when user has no XP at all.
 */
class StartupInstructionsComponent {
  constructor() {
    // Check if user is currently authed as profile user and have different texts based on that
    const profile_username = document.getElementById('profile-username').dataset.name;
    let authed_username = null;

    let authed_el = document.getElementsByName('authed-username');
    if (authed_el.length > 0) {
      authed_username = authed_el[0].content;
    }

    if (authed_username === profile_username) {
      this.el = el(
        'div.startup-instructions', [
          el('h3', 'How to start'),
          el('p', 'It\'s easy! Just follow these 4 simple steps.'),
          el('ol', [
            el('li', [
              'Go to ',
              el('a', { href: '/my/machines' }, 'your machines page'),
              ' and create a machine.'
            ]),
            el('li', [
              'Install the ',
              el('a', { href: '/plugins' }, 'Code::Stats plugin'),
              ' in your favourite editor.'
            ]),
            el('li', 'Copy your machine\'s API key to the plugin settings.'),
            el('li', 'Start writing code and you should see your gathered XP appear!')
          ])
        ]
      );
    }
    else {
      this.el = el('div.startup-instructions', [
        el('h3', 'It looks like this user hasn\'t written anything yet. 😮')
      ]);
    }
  }
}

export default StartupInstructionsComponent;
