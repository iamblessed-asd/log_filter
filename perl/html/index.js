async function search() {
  const addr = document.getElementById("address").value;
  if (!addr) return;

  const res = await fetch(`/cgi-bin/api.pl?address=${encodeURIComponent(addr)}`);
  const result = await res.json();
  const data = result["results"];
  const moreLimit = result["more"];

  const resHeader = document.getElementById("res_header");
  if (moreLimit != 1) {
    resHeader.innerHTML = "Результаты:";
  } else {
    resHeader.innerHTML = "Результаты: (количество записей больше лимита (по умолчанию 100), выведен лимит записей)";
  }


  const ul = document.getElementById("results");
  ul.innerHTML = "";

  if (data.length === 0) {
    ul.innerHTML = "<li>Ничего не найдено</li>";
  } else {
    data.forEach(row => {
      const li = document.createElement("li");
      //li.textContent = `${row.created} ${row.int_id} ${row.str}`;
      li.textContent = `${row.created} ${row.str}`;
      ul.appendChild(li);
    });
  }
}
