import ActionDropdown from './components/ActionDropdown'
import CreateResourceButton from './components/CreateResourceButton'
import ActionButtonSelector from './components/ActionButtonSelector'
import InlineActionDropdown from './components/InlineActionDropdown'

Nova.booting(app => {
  app.component('ActionDropdown', ActionDropdown)
  app.component('CreateResourceButton', CreateResourceButton)
  app.component('DetailActionDropdown', ActionButtonSelector)
  app.component('InlineActionDropdown', InlineActionDropdown)
})
