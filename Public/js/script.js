let msnry;

document.addEventListener("DOMContentLoaded", ev => {
    msnry = setupMasonry();
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
            case "edit":
            case "upVote":
                updateCards(json);
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
        msnry.layout();
    });
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
    elem.className = "grid-item";
    elem.style = `height:${120 + card.voteCount * 20}px;`;
    elem.id = card.id;
    elem.innerHTML = `<h3 class="message">${card.message}</h3>`;
    return elem;
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
        columnWidth: 168
    });
}
