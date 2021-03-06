let visualization;

function setupViz(dataset) {
  visualization = d3plus.viz()
    .container("#viz")
    .title("Autumn Event")
    .data(dataset)
    .type("bubbles")
    .id(["category", "id"])
    .depth(1)
    .size({
      "scale": {
        "range": {
          "min": 50,
          "max": 100
        }
      },
      "value": "voteCount"
    })
    .text({ "category": "category", "id": "message" })
    .color("message")
    // .width(window.innerWidth)
    .legend(false)
   // .tooltip(false)
    .mouse({
      "click": (point, viz) => {
        upVote(point.id);
      }
    })
    .draw();
}

function upVote(id) {
  const payload = {
    action: "upVote",
    card: { voteCount: 0, id: id, message: "", category: "" }
  };
  socket.send(JSON.stringify(payload));
}

function newCard(message, category) {
  const payload = {
    action: "new",
    card: { voteCount: 1, message: message, category: category }
  };
  socket.send(JSON.stringify(payload));
}

function setupForm() {
  const form = document.getElementById("newCard");
  form.addEventListener("submit", ev => {
    const message = ev.srcElement.elements.message.value;
    const dropDown = ev.srcElement.category;
    const selectedCategory = dropDown.options[dropDown.selectedIndex].value;
    ev.srcElement.elements.message.value = "";
    ev.preventDefault();
    if (message.trim() == "") {
      return;
    }
    newCard(message, selectedCategory);
    return;
  });
}

window.addEventListener('resize', () => {
  visualization.width(window.innerWidth)
    .draw()
});

const protocol = window.location.protocol.replace("http", "ws");
const endpoint = `${protocol}//${window.location.hostname}:${window.location.port}/vote/${window.location.pathname.split("/").pop()}`;
const socket = new WebSocket(endpoint);

socket.addEventListener("message", ev => {
  const reader = new FileReader();
  reader.addEventListener("loadend", (ev) => {
    const text = ev.srcElement.result;
    const json = JSON.parse(text);
    const dataset = json["success"];
    const error = json["failure"];
    if (error != null) {
      alert(error);
      return;
    }
    if (dataset != null) {
      if (visualization == null) {
        setupViz(dataset);
      } else {
        visualization.data(dataset)
          .draw();
      }
    }
  });
  reader.readAsText(ev.data);
});

setupForm();

