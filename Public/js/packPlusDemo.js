/*
(point) => {
    return 1 + point.voteCount;
  }
*/

let visualization;

function setupViz(dataset) {
  visualization = d3plus.viz()
    .container("#viz")
    .data(dataset)
    .type("bubbles")
    .id(["category", "id"])
    .depth(1)
    .size("voteCount")
    //  .size({"value": "VoteCount"})//, "scale": {"min": 1}})
    .text({ "category": "category", "id": "message" })
    .color("message")
    // .width(window.innerWidth)
    .legend(false)
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

function newCard(message) {
  const payload = {
    action: "new",
    card: { voteCount: 1, message: message, category: "glad" }
  };
  socket.send(JSON.stringify(payload));
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
    newCard(message)
    return;
  });
}

window.addEventListener('resize', () => {
  visualization.width(window.innerWidth)
    .draw()
});

const protocol = window.location.protocol.replace("http", "ws");
const endpoint = `${ protocol }//${ window.location.hostname }:8080/dotVote`;
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

