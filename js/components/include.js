document.addEventListener('DOMContentLoaded', () => {

    
    document.querySelectorAll('[data-include]').forEach(el => {
        const url = el.getAttribute('data-include');
        fetch(url)
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                return response.text();
            })
            .then(html => {
                el.outerHTML = html;
            })
            .catch(error => {
                console.error('Error al incluir el archivo:', url, error);
                el.innerHTML = ``;
            });
    });

    document.body.addEventListener('click', e => {
        if (e.target.matches('[data-action="toggle-menu"]')) {
            const nav = document.querySelector('.nav');
            if (nav) {
                nav.classList.toggle('is-active'); 
            }
        }
    });
});

/*
    document.querySelectorAll('[data-include]').forEach(el => {

    const url = el.getAttribute('data-include');

    fetch(url)

        .then(r => r.text())

        .then(h => {

            el.innerHTML = h;

        })

        .catch(() => {

            el.innerHTML = '<!-- include failed: ' + url + ' -->';

        });

});



document.addEventListener('click', e => {

    if (e.target.matches('[data-action="toggle-menu"]')) {

        const nav = document.querySelector('.nav');

        nav.style.display = (nav.style.display === 'block' ? '' : 'block');

    }

}); 
*/