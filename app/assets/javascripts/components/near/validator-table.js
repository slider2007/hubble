class ValidatorTable {
  constructor( container, skipColumns ) {
    this.container = container
    this.skipColumns = skipColumns || []
    this.searchBox = $('.validator-table-header .validator-search')
  }

  search() {
    const term = `${this.searchBox.val()} ${App.config.currentValidatorFilter}`
    this.table.search(term).draw()
  }

  settingsPopoverContent() {
    const generateContent = ( button ) => {
      const contentEl = $(button).siblings('.validator-table-settings')
      const html = $(contentEl.html())
      return html
        .find('button').click( ( e ) => {
          const button = $(e.currentTarget)
          const target = button.data('target')
          App.config.currentValidatorFilter = target
          button.addClass('active').siblings().removeClass('active')
          this.search()
        } )
        .end()
        .find(`button[data-target=${App.config.currentValidatorFilter}]`)
        .addClass('active')
        .end()
    }
    return function() {
      return generateContent( this )
    }
  }

  render() {
    this.table = this.container.find('table').DataTable( {
      sDom: 'lrtip',
      paging: false,
      autoWidth: false,
      className: 'validator-table',
      order: [
        [2, 'desc'],
        [3, 'desc']
      ],
    })

    this.searchBox.keyup( () => this.search( this.table ) )

    $('.validator-table-header .validator-table-settings-target').popover( {
      html: true,
      placement: 'bottom',
      offset: '-40%p',
      content: this.settingsPopoverContent()
    } )

    // Apply all default filters
    this.search(this.table);
  }
}

window.App.Near.ValidatorTable = ValidatorTable
