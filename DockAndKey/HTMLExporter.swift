import Foundation

enum HTMLExporter {

    static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    static func writeTempFile(for g: Guidebook, pro: Bool) -> URL? {
        let base = g.name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent((base.isEmpty ? "guidebook" : base) + ".html")
        do {
            try html(for: g, pro: pro).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    static func html(for g: Guidebook, pro: Bool) -> String {
        let name = esc(g.name)

        // The "Ask the house" helper answers only from the guidebook's own content.
        var kb: [[String: Any]] = []
        if !g.wifiNetwork.isEmpty || !g.wifiPassword.isEmpty {
            var a = "Network: \(g.wifiNetwork)."
            if !g.wifiPassword.isEmpty { a += " Password: \(g.wifiPassword)." }
            kb.append(["k": ["wifi", "wi-fi", "internet", "password", "network"], "a": a])
        }
        kb.append(["k": ["check in", "check-in", "arrive", "arrival", "door", "code"],
                   "a": "Check-in is \(g.checkIn). \(g.doorCode)"])
        var checkoutAnswer = "Checkout is \(g.checkOut)."
        let steps = g.checkout.map { $0.text }.filter { !$0.isEmpty }
        if !steps.isEmpty { checkoutAnswer += " Before you go: " + steps.joined(separator: "; ") + "." }
        kb.append(["k": ["checkout", "check out", "leave", "leaving"], "a": checkoutAnswer])
        if !g.parking.isEmpty {
            kb.append(["k": ["park", "parking", "trailer", "car"], "a": g.parking])
        }
        let allCards = g.houseCards + (g.showDock ? g.dockCards : [])
        for card in allCards where !card.title.isEmpty {
            let keys = card.title.lowercased().split(separator: " ").map(String.init)
            kb.append(["k": keys, "a": card.body.isEmpty ? card.title : card.body])
        }
        let placeNames = g.places.filter { !$0.name.isEmpty }
        if !placeNames.isEmpty {
            let list = placeNames.map { p in
                p.area.isEmpty ? p.name : "\(p.name) (\(p.area))"
            }.joined(separator: "; ")
            kb.append(["k": ["eat", "dinner", "lunch", "restaurant", "food", "drink", "hungry"], "a": list])
        }
        let rulesList = g.rules.map { $0.text }.filter { !$0.isEmpty }
        if !rulesList.isEmpty {
            kb.append(["k": ["rules", "quiet", "smoking", "party", "pets"], "a": rulesList.joined(separator: ". ") + "."])
        }
        if !g.emergency.isEmpty {
            kb.append(["k": ["emergency", "hurt", "fire", "911", "help"], "a": g.emergency])
        }
        let kbJSON = (try? JSONSerialization.data(withJSONObject: kb))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        // Section bodies.
        func cardsHTML(_ cards: [HowTo]) -> String {
            cards.filter { !$0.title.isEmpty || !$0.body.isEmpty }.map { c in
                "<div class='card'><h3>\(esc(c.title))</h3><p>\(esc(c.body))</p></div>"
            }.joined()
        }
        func listHTML(_ items: [ChecklistItem], ordered: Bool) -> String {
            let lis = items.filter { !$0.text.isEmpty }
                .map { "<li>\(esc($0.text))</li>" }.joined()
            if lis.isEmpty { return "" }
            return ordered ? "<ol>\(lis)</ol>" : "<ul>\(lis)</ul>"
        }
        let placesHTML = g.places.filter { !$0.name.isEmpty }.map { p in
            "<div class='place'><strong>\(esc(p.name))</strong>"
            + (p.area.isEmpty ? "" : "<span class='meta'>\(esc(p.area))</span>")
            + (p.note.isEmpty ? "" : "<p>\(esc(p.note))</p>")
            + "</div>"
        }.joined()

        var arrivalRows = "<dt>Check-in</dt><dd>\(esc(g.checkIn))</dd><dt>Checkout</dt><dd>\(esc(g.checkOut))</dd>"
        if !g.doorCode.isEmpty { arrivalRows += "<dt>Door code</dt><dd>\(esc(g.doorCode))</dd>" }
        if !g.parking.isEmpty { arrivalRows += "<dt>Parking</dt><dd>\(esc(g.parking))</dd>" }

        var wifiCard = ""
        if !g.wifiNetwork.isEmpty || !g.wifiPassword.isEmpty {
            wifiCard = "<div class='card'><h3>Wi-Fi</h3><dl class='kv'>"
            if !g.wifiNetwork.isEmpty { wifiCard += "<dt>Network</dt><dd class='code'>\(esc(g.wifiNetwork))</dd>" }
            if !g.wifiPassword.isEmpty { wifiCard += "<dt>Password</dt><dd class='code' id='wifi'>\(esc(g.wifiPassword))</dd>" }
            wifiCard += "</dl>"
            if !g.wifiPassword.isEmpty { wifiCard += "<button class='copy' type='button' id='copyWifi'>Copy password</button>" }
            wifiCard += "</div>"
        }

        var hostLine = ""
        if !g.hostName.isEmpty || !g.hostPhone.isEmpty {
            hostLine = "<div class='card'><h3>Your host</h3><p>" + esc([g.hostName, g.hostPhone].filter { !$0.isEmpty }.joined(separator: " · ")) + "</p></div>"
        }

        // Tabs.
        var tabs = "<button class='tab on' data-s='arrive'>Arrival</button><button class='tab' data-s='house'>The house</button>"
        if g.showDock { tabs += "<button class='tab' data-s='dock'>Dock &amp; lake</button>" }
        if !placesHTML.isEmpty { tabs += "<button class='tab' data-s='eat'>Eat &amp; drink</button>" }
        tabs += "<button class='tab' data-s='out'>Checkout</button>"
        // "Ask the house" is a Pro feature.
        if pro { tabs += "<button class='tab' data-s='ask'>Ask the house</button>" }

        var sections = "<section id='arrive'><h2>Arrival</h2><div class='card'><dl class='kv'>\(arrivalRows)</dl></div>\(wifiCard)"
        if !g.emergency.isEmpty { sections += "<div class='card warn'><h3>In an emergency</h3><p>\(esc(g.emergency))</p></div>" }
        sections += hostLine + "</section>"

        sections += "<section id='house' hidden><h2>The house</h2>\(cardsHTML(g.houseCards))"
        let rulesHTML = listHTML(g.rules, ordered: false)
        if !rulesHTML.isEmpty { sections += "<div class='card'><h3>House rules</h3>\(rulesHTML)</div>" }
        sections += "</section>"

        if g.showDock {
            sections += "<section id='dock' hidden><h2>Dock &amp; lake</h2>\(cardsHTML(g.dockCards))</section>"
        }
        if !placesHTML.isEmpty {
            sections += "<section id='eat' hidden><h2>Eat &amp; drink</h2><div class='card'>\(placesHTML)</div></section>"
        }
        sections += "<section id='out' hidden><h2>Checkout by \(esc(g.checkOut))</h2><div class='card'>\(listHTML(g.checkout, ordered: true))</div></section>"

        if pro { sections += "<section id='ask' hidden><h2>Ask the house</h2><p class='note'>Answers come only from this guidebook. If it doesn't know, message your host.</p><div class='log' id='log'><div class='msg house'>Hi! Ask me about Wi-Fi, checkout, dinner, or anything else in the house.</div></div><form class='ask' id='ask-form'><input id='q' autocomplete='off' placeholder='Type a question' aria-label='Your question'><button type='submit'>Ask</button></form></section>" }

        let footerText = pro
            ? "Your guide to \(name)"
            : "Your guide to \(name) · Made with Dock &amp; Key"

        let css = """
        :root{--bg:#F3F6F4;--surface:#fff;--ink:#13302D;--muted:#5C716D;--line:#D9E2DF;--lake:#1F6F6A;--brass:#B8893F;--buoy:#C0432E}
        @media (prefers-color-scheme:dark){:root{--bg:#0E1C1A;--surface:#152826;--ink:#E6EFEC;--muted:#9DB2AD;--line:#26403C;--lake:#6FC1B8;--brass:#D9B26F;--buoy:#E7765F}}
        *{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.55 -apple-system,system-ui,sans-serif}
        .wrap{max-width:560px;margin:0 auto;padding:0 16px 48px}
        header{padding:22px 0 12px}h1{font-size:2rem;line-height:1.1;margin:0;font-family:Georgia,serif}
        .sub{color:var(--muted);margin:6px 0 0}
        nav{position:sticky;top:0;background:var(--bg);display:flex;gap:6px;overflow-x:auto;padding:10px 0;border-bottom:1px solid var(--line)}
        .tab{flex:none;border:1px solid var(--line);background:var(--surface);color:var(--ink);font:600 14px -apple-system,system-ui,sans-serif;padding:8px 14px;border-radius:999px;cursor:pointer}
        .tab.on{background:var(--lake);border-color:var(--lake);color:var(--bg)}
        section{padding-top:18px}h2{font-size:1.4rem;margin:0 0 12px;font-family:Georgia,serif}
        h3{font-size:1rem;margin:0 0 6px}p{margin:0}
        .card{background:var(--surface);border:1px solid var(--line);border-radius:12px;padding:16px;margin-bottom:12px}
        .card p{white-space:pre-line}
        .kv{margin:0;display:grid;grid-template-columns:auto 1fr;gap:6px 14px}
        .kv dt{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted)}
        .kv dd{margin:0;font-weight:600;overflow-wrap:anywhere}
        .code{font-family:ui-monospace,monospace}
        .copy{margin-top:10px;border:1px solid var(--lake);background:none;color:var(--lake);font:600 13px -apple-system,system-ui,sans-serif;padding:6px 12px;border-radius:8px;cursor:pointer}
        .warn{border-left:4px solid var(--buoy)}
        ul,ol{margin:0;padding-left:1.3em}li{margin:4px 0}
        .place{padding:10px 0;border-top:1px solid var(--line)}.place:first-child{border-top:0;padding-top:0}
        .place .meta{display:block;font-size:12px;color:var(--muted)}
        .note{color:var(--muted);font-size:14px;margin-bottom:10px}
        .log{display:grid;gap:8px;margin-bottom:10px}
        .msg{max-width:88%;padding:10px 13px;border-radius:14px;font-size:15px}
        .msg.guest{justify-self:end;background:var(--lake);color:var(--bg)}
        .msg.house{justify-self:start;background:var(--surface);border:1px solid var(--line)}
        .ask{display:flex;gap:8px}
        .ask input{flex:1;min-width:0;font:16px -apple-system,system-ui,sans-serif;padding:10px 12px;border:1px solid var(--line);border-radius:10px;background:var(--surface);color:var(--ink)}
        .ask button{border:0;background:var(--brass);color:#13302D;font:700 15px -apple-system,system-ui,sans-serif;padding:0 16px;border-radius:10px;cursor:pointer}
        footer{margin-top:28px;padding-top:14px;border-top:1px solid var(--line);color:var(--muted);font-size:13px}
        """

        let js = """
        var tabs=document.querySelectorAll('.tab');var secs=document.querySelectorAll('section');
        tabs.forEach(function(t){t.addEventListener('click',function(){
          tabs.forEach(function(x){x.classList.toggle('on',x===t)});
          secs.forEach(function(s){s.hidden=(s.id!==t.getAttribute('data-s'))});
        });});
        var cw=document.getElementById('copyWifi');
        if(cw){cw.addEventListener('click',function(){
          var txt=document.getElementById('wifi').textContent;
          if(navigator.clipboard&&navigator.clipboard.writeText){navigator.clipboard.writeText(txt).then(function(){cw.textContent='Copied';});}
        });}
        function answer(q){q=q.toLowerCase();var best=null,score=0;
          kb.forEach(function(e){var n=0;e.k.forEach(function(k){if(q.indexOf(k)>-1)n++});if(n>score){score=n;best=e}});
          return best?best.a:'That one is not in the guide yet. Message your host and they will get right back to you.';}
        var log=document.getElementById('log');
        function add(t,w){var d=document.createElement('div');d.className='msg '+w;d.textContent=t;log.appendChild(d);d.scrollIntoView({block:'nearest'});}
        var af=document.getElementById('ask-form');
        if(af)af.addEventListener('submit',function(e){
          e.preventDefault();var i=document.getElementById('q');var v=i.value.trim();if(!v)return;
          add(v,'guest');setTimeout(function(){add(answer(v),'house')},300);i.value='';});
        """

        var out = "<!doctype html><html lang='en'><head><meta charset='utf-8'>"
        out += "<meta name='viewport' content='width=device-width,initial-scale=1'>"
        out += "<title>\(name)</title><style>\(css)</style></head><body><div class='wrap'>"
        out += "<header><h1>Welcome to \(name)</h1>"
        if !g.subtitle.isEmpty { out += "<p class='sub'>\(esc(g.subtitle))</p>" }
        out += "</header><nav>\(tabs)</nav>\(sections)"
        out += "<footer>\(footerText)</footer></div>"
        out += "<script>var kb=\(kbJSON);\n\(js)</script></body></html>"
        return out
    }
}
