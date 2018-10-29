let msnry;

document.addEventListener("DOMContentLoaded", ev => {
    msnry = setupMasonry();
    setupForm();
});

const socket = new WebSocket("ws://localhost:8080/dotVote");
socket.onopen = function (ws) {
    // socket.send("hiya");
}

socket.addEventListener("message", ev => {
    const reader = new FileReader();
    reader.addEventListener("loadend", (ev) => {
        const text = ev.srcElement.result;
        const json = JSON.parse(text);

        switch (json.action) {
            case "new":
                addNewCards(json);
                break;
            case "downVote":
            case "upVote":
                upDownVoteCards(json);
                break;
                case "edit":
                break;
        }

        console.log(json);
    });
    reader.readAsText(ev.data);
})

function updateCards(json) {
    json.cards.forEach(card => {
        const elem = document.getElementById(card.id);
        const newElement = getCardElement(card);
        elem.replaceWith(newElement);
    });
    msnry.layout();
}

function upDownVoteCards(json) {
    json.cards.forEach(card => {
        const elem = document.getElementById(card.id);
        //elem.style = getStyle(card);
        elem.className = getClassName(card);
    });
    msnry.layout();
}

function addNewCards(json) {
    const grid = document.querySelector('.grid');
    const cardElements = json.cards.map(card => {
        return getCardElement(card);
    });
    const fragment = document.createDocumentFragment();
    cardElements.forEach(elem => {
        fragment.appendChild(elem);
    })
    grid.appendChild(fragment);
    msnry.appended(cardElements);
}

function getCardElement(card) {
    const elem = document.createElement('div');
    elem.className = getClassName(card);
    //elem.style = getStyle(card);
    elem.id = card.id;
    elem.innerHTML = `<h3 class="message">${card.message}</h3>`;
    return elem;
}

function getClassName(card) {
    const width = Math.min(5,  Math.floor((card.voteCount + 3) / 2));
    const height = Math.min(5, Math.floor((card.voteCount + 2) / 2));
    return `grid-item grid-item--width${width} grid-item--height${height}`;
}

function getStyle(card) {
    const size = 100 + card.voteCount * 20;
    return `width: ${size}px; height:${size}px;`
}

function setupMasonry() {
    const grid = document.querySelector('.grid');
    grid.addEventListener("click", (ev) => {
        if (!matchesSelector(ev.target, '.grid-item')) {
            return;
        }
        const payload = {
            action: "upVote",
            cards: [
                { voteCount: 0, id: ev.srcElement.id, message: "", category: "" }
            ]
        };
        socket.send(JSON.stringify(payload));
    });
    return new Masonry(grid, {
        itemSelector: '.grid-item',
        columnWidth: 32,
        gutter: 10,
        originTop: false,
        stagger: 30
    });
}

function setupForm() {
    const form = document.getElementById("newCard");
    form.addEventListener("submit", ev => {
        const message = ev.srcElement.elements.message.value;
        ev.srcElement.elements.message.value = "";
        ev.preventDefault();
        if (message.trim() == "") {
            return;
        }
        const payload = {
            action: "new",
            cards: [
                { voteCount: 0, message: message, category: "" }
            ]
        };
        socket.send(JSON.stringify(payload));
        return;
    });
}
