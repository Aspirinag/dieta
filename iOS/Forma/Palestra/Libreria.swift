import Foundation

// Esercizi predefiniti e routine iniziale (la scheda della vecchia app Palestra)
enum Libreria {
    // Libreria ampia per muscolo e attrezzo (sul modello di Hevy e Strong). I primi 7 sono quelli della vecchia scheda
    static let predefiniti: [Esercizio] = [
        Esercizio(nome: "Leg press", muscolo: .quadricipiti, attrezzo: .macchina),
        Esercizio(nome: "Chest press", muscolo: .petto, attrezzo: .macchina),
        Esercizio(nome: "Lat machine", muscolo: .schiena, attrezzo: .cavi),
        Esercizio(nome: "Leg curl", muscolo: .femorali, attrezzo: .macchina),
        Esercizio(nome: "Shoulder press", muscolo: .spalle, attrezzo: .macchina),
        Esercizio(nome: "Seated row", muscolo: .schiena, attrezzo: .cavi),
        Esercizio(nome: "Addominali", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Panca piana", muscolo: .petto, attrezzo: .bilanciere),
        Esercizio(nome: "Panca piana con manubri", muscolo: .petto, attrezzo: .manubri),
        Esercizio(nome: "Panca inclinata", muscolo: .petto, attrezzo: .bilanciere),
        Esercizio(nome: "Panca inclinata con manubri", muscolo: .petto, attrezzo: .manubri),
        Esercizio(nome: "Panca declinata", muscolo: .petto, attrezzo: .bilanciere),
        Esercizio(nome: "Panca piana al multipower", muscolo: .petto, attrezzo: .smith),
        Esercizio(nome: "Panca inclinata al multipower", muscolo: .petto, attrezzo: .smith),
        Esercizio(nome: "Croci con manubri", muscolo: .petto, attrezzo: .manubri),
        Esercizio(nome: "Croci su panca inclinata", muscolo: .petto, attrezzo: .manubri),
        Esercizio(nome: "Croci ai cavi alti", muscolo: .petto, attrezzo: .cavi),
        Esercizio(nome: "Croci ai cavi bassi", muscolo: .petto, attrezzo: .cavi),
        Esercizio(nome: "Pectoral machine", muscolo: .petto, attrezzo: .macchina),
        Esercizio(nome: "Chest press inclinata", muscolo: .petto, attrezzo: .macchina),
        Esercizio(nome: "Piegamenti", muscolo: .petto, attrezzo: .corpoLibero),
        Esercizio(nome: "Piegamenti inclinati", muscolo: .petto, attrezzo: .corpoLibero),
        Esercizio(nome: "Dip alle parallele (petto)", muscolo: .petto, attrezzo: .corpoLibero),
        Esercizio(nome: "Pullover con manubrio", muscolo: .petto, attrezzo: .manubri),
        Esercizio(nome: "Trazioni", muscolo: .schiena, attrezzo: .corpoLibero),
        Esercizio(nome: "Trazioni presa inversa", muscolo: .schiena, attrezzo: .corpoLibero),
        Esercizio(nome: "Trazioni assistite", muscolo: .schiena, attrezzo: .macchina),
        Esercizio(nome: "Trazioni zavorrate", muscolo: .schiena, attrezzo: .bilancierePesato),
        Esercizio(nome: "Lat machine presa stretta", muscolo: .schiena, attrezzo: .cavi),
        Esercizio(nome: "Lat machine presa inversa", muscolo: .schiena, attrezzo: .cavi),
        Esercizio(nome: "Lat machine dietro (presa larga)", muscolo: .schiena, attrezzo: .cavi),
        Esercizio(nome: "Pulley basso", muscolo: .schiena, attrezzo: .cavi),
        Esercizio(nome: "Pulley presa larga", muscolo: .schiena, attrezzo: .cavi),
        Esercizio(nome: "Rematore con bilanciere", muscolo: .schiena, attrezzo: .bilanciere),
        Esercizio(nome: "Rematore con manubrio", muscolo: .schiena, attrezzo: .manubri),
        Esercizio(nome: "Rematore su panca inclinata", muscolo: .schiena, attrezzo: .manubri),
        Esercizio(nome: "Rematore T-bar", muscolo: .schiena, attrezzo: .bilanciere),
        Esercizio(nome: "Rematore alla macchina", muscolo: .schiena, attrezzo: .macchina),
        Esercizio(nome: "Rematore al multipower", muscolo: .schiena, attrezzo: .smith),
        Esercizio(nome: "Rematore inverso", muscolo: .schiena, attrezzo: .corpoLibero),
        Esercizio(nome: "Pullover ai cavi", muscolo: .schiena, attrezzo: .cavi),
        Esercizio(nome: "Stacco da terra", muscolo: .schiena, attrezzo: .bilanciere),
        Esercizio(nome: "Stacco sumo", muscolo: .schiena, attrezzo: .bilanciere),
        Esercizio(nome: "Hyperextension", muscolo: .lombari, attrezzo: .corpoLibero),
        Esercizio(nome: "Good morning", muscolo: .lombari, attrezzo: .bilanciere),
        Esercizio(nome: "Scrollate con bilanciere", muscolo: .trapezi, attrezzo: .bilanciere),
        Esercizio(nome: "Scrollate con manubri", muscolo: .trapezi, attrezzo: .manubri),
        Esercizio(nome: "Lento avanti con bilanciere", muscolo: .spalle, attrezzo: .bilanciere),
        Esercizio(nome: "Lento avanti con manubri", muscolo: .spalle, attrezzo: .manubri),
        Esercizio(nome: "Military press in piedi", muscolo: .spalle, attrezzo: .bilanciere),
        Esercizio(nome: "Arnold press", muscolo: .spalle, attrezzo: .manubri),
        Esercizio(nome: "Shoulder press al multipower", muscolo: .spalle, attrezzo: .smith),
        Esercizio(nome: "Alzate laterali", muscolo: .spalle, attrezzo: .manubri),
        Esercizio(nome: "Alzate laterali ai cavi", muscolo: .spalle, attrezzo: .cavi),
        Esercizio(nome: "Alzate laterali alla macchina", muscolo: .spalle, attrezzo: .macchina),
        Esercizio(nome: "Alzate frontali", muscolo: .spalle, attrezzo: .manubri),
        Esercizio(nome: "Alzate frontali con disco", muscolo: .spalle, attrezzo: .altro),
        Esercizio(nome: "Alzate posteriori", muscolo: .spalle, attrezzo: .manubri),
        Esercizio(nome: "Reverse fly alla macchina", muscolo: .spalle, attrezzo: .macchina),
        Esercizio(nome: "Face pull", muscolo: .spalle, attrezzo: .cavi),
        Esercizio(nome: "Tirate al mento", muscolo: .spalle, attrezzo: .bilanciere),
        Esercizio(nome: "Curl con bilanciere", muscolo: .bicipiti, attrezzo: .bilanciere),
        Esercizio(nome: "Curl con bilanciere EZ", muscolo: .bicipiti, attrezzo: .bilanciere),
        Esercizio(nome: "Curl con manubri", muscolo: .bicipiti, attrezzo: .manubri),
        Esercizio(nome: "Curl alternato", muscolo: .bicipiti, attrezzo: .manubri),
        Esercizio(nome: "Hammer curl", muscolo: .bicipiti, attrezzo: .manubri),
        Esercizio(nome: "Curl concentrato", muscolo: .bicipiti, attrezzo: .manubri),
        Esercizio(nome: "Curl su panca inclinata", muscolo: .bicipiti, attrezzo: .manubri),
        Esercizio(nome: "Curl alla panca Scott", muscolo: .bicipiti, attrezzo: .bilanciere),
        Esercizio(nome: "Curl al cavo", muscolo: .bicipiti, attrezzo: .cavi),
        Esercizio(nome: "Curl alla macchina", muscolo: .bicipiti, attrezzo: .macchina),
        Esercizio(nome: "Curl inverso", muscolo: .avambracci, attrezzo: .bilanciere),
        Esercizio(nome: "Curl dei polsi", muscolo: .avambracci, attrezzo: .manubri),
        Esercizio(nome: "Push down al cavo", muscolo: .tricipiti, attrezzo: .cavi),
        Esercizio(nome: "Push down con corda", muscolo: .tricipiti, attrezzo: .cavi),
        Esercizio(nome: "French press", muscolo: .tricipiti, attrezzo: .bilanciere),
        Esercizio(nome: "French press con manubri", muscolo: .tricipiti, attrezzo: .manubri),
        Esercizio(nome: "Estensioni sopra la testa con manubrio", muscolo: .tricipiti, attrezzo: .manubri),
        Esercizio(nome: "Estensioni sopra la testa al cavo", muscolo: .tricipiti, attrezzo: .cavi),
        Esercizio(nome: "Kickback con manubrio", muscolo: .tricipiti, attrezzo: .manubri),
        Esercizio(nome: "Panca presa stretta", muscolo: .tricipiti, attrezzo: .bilanciere),
        Esercizio(nome: "Dip", muscolo: .tricipiti, attrezzo: .corpoLibero),
        Esercizio(nome: "Dip alla panca", muscolo: .tricipiti, attrezzo: .corpoLibero),
        Esercizio(nome: "Tricipiti alla macchina", muscolo: .tricipiti, attrezzo: .macchina),
        Esercizio(nome: "Squat", muscolo: .quadricipiti, attrezzo: .bilanciere),
        Esercizio(nome: "Front squat", muscolo: .quadricipiti, attrezzo: .bilanciere),
        Esercizio(nome: "Squat al multipower", muscolo: .quadricipiti, attrezzo: .smith),
        Esercizio(nome: "Goblet squat", muscolo: .quadricipiti, attrezzo: .kettlebell),
        Esercizio(nome: "Squat a corpo libero", muscolo: .quadricipiti, attrezzo: .corpoLibero),
        Esercizio(nome: "Hack squat", muscolo: .quadricipiti, attrezzo: .macchina),
        Esercizio(nome: "Pendulum squat", muscolo: .quadricipiti, attrezzo: .macchina),
        Esercizio(nome: "Leg press orizzontale", muscolo: .quadricipiti, attrezzo: .macchina),
        Esercizio(nome: "Leg extension", muscolo: .quadricipiti, attrezzo: .macchina),
        Esercizio(nome: "Affondi con manubri", muscolo: .quadricipiti, attrezzo: .manubri),
        Esercizio(nome: "Affondi con bilanciere", muscolo: .quadricipiti, attrezzo: .bilanciere),
        Esercizio(nome: "Affondi in camminata", muscolo: .quadricipiti, attrezzo: .manubri),
        Esercizio(nome: "Affondi bulgari", muscolo: .quadricipiti, attrezzo: .manubri),
        Esercizio(nome: "Step up", muscolo: .quadricipiti, attrezzo: .manubri),
        Esercizio(nome: "Sissy squat", muscolo: .quadricipiti, attrezzo: .corpoLibero),
        Esercizio(nome: "Leg curl seduto", muscolo: .femorali, attrezzo: .macchina),
        Esercizio(nome: "Leg curl sdraiato", muscolo: .femorali, attrezzo: .macchina),
        Esercizio(nome: "Stacco rumeno", muscolo: .femorali, attrezzo: .bilanciere),
        Esercizio(nome: "Stacco rumeno con manubri", muscolo: .femorali, attrezzo: .manubri),
        Esercizio(nome: "Stacco a gambe tese", muscolo: .femorali, attrezzo: .bilanciere),
        Esercizio(nome: "Nordic curl", muscolo: .femorali, attrezzo: .corpoLibero),
        Esercizio(nome: "Hip thrust", muscolo: .glutei, attrezzo: .bilanciere),
        Esercizio(nome: "Hip thrust alla macchina", muscolo: .glutei, attrezzo: .macchina),
        Esercizio(nome: "Ponte glutei", muscolo: .glutei, attrezzo: .corpoLibero),
        Esercizio(nome: "Slanci ai cavi", muscolo: .glutei, attrezzo: .cavi),
        Esercizio(nome: "Glute kickback alla macchina", muscolo: .glutei, attrezzo: .macchina),
        Esercizio(nome: "Abductor machine", muscolo: .abduttori, attrezzo: .macchina),
        Esercizio(nome: "Adductor machine", muscolo: .adduttori, attrezzo: .macchina),
        Esercizio(nome: "Calf raise in piedi", muscolo: .polpacci, attrezzo: .macchina),
        Esercizio(nome: "Calf raise seduto", muscolo: .polpacci, attrezzo: .macchina),
        Esercizio(nome: "Calf alla leg press", muscolo: .polpacci, attrezzo: .macchina),
        Esercizio(nome: "Calf raise con manubri", muscolo: .polpacci, attrezzo: .manubri),
        Esercizio(nome: "Crunch", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Crunch al cavo", muscolo: .addominali, attrezzo: .cavi),
        Esercizio(nome: "Crunch alla macchina", muscolo: .addominali, attrezzo: .macchina),
        Esercizio(nome: "Crunch inverso", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Plank", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Plank laterale", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Russian twist", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Sollevamento gambe alla sbarra", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Sollevamento gambe a terra", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Mountain climber", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Dead bug", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Ab wheel", muscolo: .addominali, attrezzo: .altro),
        Esercizio(nome: "Woodchopper al cavo", muscolo: .addominali, attrezzo: .cavi),
        Esercizio(nome: "Pallof press", muscolo: .addominali, attrezzo: .cavi),
        Esercizio(nome: "Kettlebell swing", muscolo: .corpoIntero, attrezzo: .kettlebell),
        Esercizio(nome: "Clean con bilanciere", muscolo: .corpoIntero, attrezzo: .bilanciere),
        Esercizio(nome: "Thruster", muscolo: .corpoIntero, attrezzo: .bilanciere),
        Esercizio(nome: "Burpees", muscolo: .corpoIntero, attrezzo: .corpoLibero),
        Esercizio(nome: "Farmer walk", muscolo: .corpoIntero, attrezzo: .manubri),
        Esercizio(nome: "Turkish get-up", muscolo: .corpoIntero, attrezzo: .kettlebell),
        Esercizio(nome: "Box jump", muscolo: .corpoIntero, attrezzo: .corpoLibero),
        Esercizio(nome: "Battle rope", muscolo: .corpoIntero, attrezzo: .altro),
        Esercizio(nome: "Tapis roulant", muscolo: .cardio, attrezzo: .macchina),
        Esercizio(nome: "Cyclette", muscolo: .cardio, attrezzo: .macchina),
        Esercizio(nome: "Ellittica", muscolo: .cardio, attrezzo: .macchina),
        Esercizio(nome: "Vogatore", muscolo: .cardio, attrezzo: .macchina),
        Esercizio(nome: "Stair climber", muscolo: .cardio, attrezzo: .macchina),
        Esercizio(nome: "Salto della corda", muscolo: .cardio, attrezzo: .altro),
        Esercizio(nome: "Rematore con elastico", muscolo: .schiena, attrezzo: .elastico),
        Esercizio(nome: "Curl con elastico", muscolo: .bicipiti, attrezzo: .elastico),
        Esercizio(nome: "Alzate laterali con elastico", muscolo: .spalle, attrezzo: .elastico),
        Esercizio(nome: "Monster walk con elastico", muscolo: .abduttori, attrezzo: .elastico),
        Esercizio(nome: "Crunch su panca declinata", muscolo: .addominali, attrezzo: .altro),
        Esercizio(nome: "Crunch obliqui", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Crunch con manubrio", muscolo: .addominali, attrezzo: .manubri),
        Esercizio(nome: "Sit-up", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "V-up", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Hollow hold", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Bicycle crunch", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Toccata talloni", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Flutter kicks", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Sollevamento ginocchia alla sedia romana", muscolo: .addominali, attrezzo: .altro),
        Esercizio(nome: "Sollevamento gambe su panca", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Plank con tocco spalle", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Bird dog", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Rotary torso alla macchina", muscolo: .addominali, attrezzo: .macchina),
        Esercizio(nome: "Piegamenti laterali con manubrio", muscolo: .addominali, attrezzo: .manubri),
        Esercizio(nome: "Russian twist con disco", muscolo: .addominali, attrezzo: .altro),
        Esercizio(nome: "Ab wheel in ginocchio", muscolo: .addominali, attrezzo: .altro),
        Esercizio(nome: "Crunch alla fitball", muscolo: .addominali, attrezzo: .altro),
        Esercizio(nome: "Stir the pot alla fitball", muscolo: .addominali, attrezzo: .altro),
        Esercizio(nome: "Woodchopper basso-alto al cavo", muscolo: .addominali, attrezzo: .cavi),
        Esercizio(nome: "Crunch in ginocchio al cavo", muscolo: .addominali, attrezzo: .cavi),
        Esercizio(nome: "Dragon flag", muscolo: .addominali, attrezzo: .corpoLibero),
        Esercizio(nome: "Kettlebell swing a una mano", muscolo: .corpoIntero, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell clean", muscolo: .corpoIntero, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell snatch", muscolo: .corpoIntero, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell clean and press", muscolo: .corpoIntero, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell thruster", muscolo: .corpoIntero, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell high pull", muscolo: .trapezi, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell press", muscolo: .spalle, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell push press", muscolo: .spalle, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell halo", muscolo: .spalle, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell windmill", muscolo: .addominali, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell around the world", muscolo: .addominali, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell russian twist", muscolo: .addominali, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell farmer walk", muscolo: .corpoIntero, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell suitcase carry", muscolo: .addominali, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell rack carry", muscolo: .addominali, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell stacco", muscolo: .femorali, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell stacco a una gamba", muscolo: .femorali, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell front squat", muscolo: .quadricipiti, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell affondi", muscolo: .quadricipiti, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell affondi inversi", muscolo: .glutei, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell sumo squat", muscolo: .adduttori, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell rematore", muscolo: .schiena, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell gorilla row", muscolo: .schiena, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell renegade row", muscolo: .schiena, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell floor press", muscolo: .petto, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell curl", muscolo: .bicipiti, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell estensioni sopra la testa", muscolo: .tricipiti, attrezzo: .kettlebell),
        Esercizio(nome: "Kettlebell hip thrust", muscolo: .glutei, attrezzo: .kettlebell),
    ]

    // Gli id (i nomi italiani) di questi esercizi: si mostrano nella lingua del telefono (`Esercizio.titolo`)
    static let nomiPredefiniti: Set<String> = Set(predefiniti.map(\.id))

    // Le schede iniziali e quelle pronte prendono il nome nella lingua del telefono al momento della creazione;
    // gli esercizi dentro si indicano per id (nome italiano), così restano gli stessi in ogni lingua
    static var routineIniziali: [Routine] {
        [Routine(nome: String(localized: "Scheda pesi"), voci: [
            VoceRoutine(esercizio: "Leg press"),
            VoceRoutine(esercizio: "Chest press"),
            VoceRoutine(esercizio: "Lat machine"),
            VoceRoutine(esercizio: "Leg curl"),
            VoceRoutine(esercizio: "Shoulder press"),
            VoceRoutine(esercizio: "Seated row"),
            VoceRoutine(esercizio: "Addominali", ripMin: 15, ripMax: 15, recupero: 60),
        ])]
    }

    // Schede pronte da copiare e modificare (divisioni classiche)
    static var modelli: [Routine] {
        func r(_ nome: String, _ voci: [(String, Int, Int, Int)]) -> Routine {
            Routine(nome: nome, voci: voci.map { VoceRoutine(esercizio: $0.0, serie: $0.1, ripMin: $0.2, ripMax: $0.3) })
        }
        return [
            r(String(localized: "Full body"), [("Squat", 3, 8, 10), ("Panca piana", 3, 8, 10), ("Rematore con bilanciere", 3, 8, 10),
                            ("Lento avanti con manubri", 3, 10, 12), ("Stacco rumeno", 3, 10, 12), ("Plank", 3, 30, 45)]),
            r(String(localized: "Push (spinta)"), [("Panca piana", 4, 6, 8), ("Panca inclinata con manubri", 3, 8, 10), ("Lento avanti con manubri", 3, 8, 10),
                                ("Alzate laterali", 3, 12, 15), ("Croci ai cavi alti", 3, 12, 15), ("Push down con corda", 3, 10, 12)]),
            r(String(localized: "Pull (tirata)"), [("Trazioni", 4, 6, 10), ("Rematore con bilanciere", 3, 8, 10), ("Pulley basso", 3, 10, 12),
                                ("Face pull", 3, 12, 15), ("Curl con bilanciere", 3, 8, 10), ("Hammer curl", 3, 10, 12)]),
            r(String(localized: "Legs (gambe)"), [("Squat", 4, 6, 8), ("Stacco rumeno", 3, 8, 10), ("Leg press", 3, 10, 12),
                               ("Leg curl", 3, 10, 12), ("Calf raise in piedi", 4, 12, 15), ("Crunch al cavo", 3, 12, 15)]),
            r(String(localized: "Upper (parte alta)"), [("Panca piana", 4, 6, 8), ("Rematore con manubrio", 4, 8, 10), ("Lento avanti con manubri", 3, 8, 10),
                                     ("Lat machine", 3, 10, 12), ("Curl con manubri", 3, 10, 12), ("Push down al cavo", 3, 10, 12)]),
            r(String(localized: "Lower (parte bassa)"), [("Squat", 4, 6, 8), ("Stacco rumeno", 3, 8, 10), ("Affondi bulgari", 3, 10, 12),
                                      ("Leg extension", 3, 12, 15), ("Hip thrust", 3, 10, 12), ("Calf raise seduto", 4, 12, 15)]),
            r(String(localized: "Macchine principiante"), [("Leg press", 3, 10, 12), ("Chest press", 3, 10, 12), ("Lat machine", 3, 10, 12),
                                        ("Leg curl", 3, 10, 12), ("Shoulder press", 3, 10, 12), ("Seated row", 3, 10, 12)]),
            r(String(localized: "Addominali (core)"), [("Crunch al cavo", 3, 12, 15), ("Sollevamento ginocchia alla sedia romana", 3, 10, 15),
                                    ("Russian twist con disco", 3, 16, 20), ("Plank", 3, 30, 45), ("Pallof press", 3, 10, 12),
                                    ("Dead bug", 3, 10, 12)]),
            r(String(localized: "Kettlebell total body"), [("Kettlebell swing", 4, 15, 20), ("Goblet squat", 3, 10, 12), ("Kettlebell press", 3, 8, 10),
                                        ("Kettlebell rematore", 3, 10, 12), ("Kettlebell stacco a una gamba", 3, 8, 10),
                                        ("Kettlebell windmill", 2, 6, 8), ("Kettlebell farmer walk", 3, 30, 40)]),
        ]
    }

    // Salvati in italiano (come nel JSON); per mostrarli si usa `nomeCardio`
    static let tipiCardio = ["Corsa", "Bici", "Ellittica", "Nuoto", "Camminata", "Vogatore", "Scale", "Cardio"]

    static func nomeCardio(_ tipo: String) -> String {
        switch tipo {
        case "Corsa": String(localized: "Corsa")
        case "Bici": String(localized: "Bici")
        case "Ellittica": String(localized: "Ellittica")
        case "Nuoto": String(localized: "Nuoto")
        case "Camminata": String(localized: "Camminata")
        case "Vogatore": String(localized: "Vogatore")
        case "Scale": String(localized: "Scale")
        case "Cardio": String(localized: "Cardio")
        default: tipo
        }
    }

    static func simboloCardio(_ tipo: String) -> String {
        switch tipo {
        case "Bici": "figure.outdoor.cycle"
        case "Ellittica": "figure.elliptical"
        case "Nuoto": "figure.pool.swim"
        case "Camminata": "figure.walk"
        case "Vogatore": "figure.rower"
        case "Scale": "figure.stair.stepper"
        case "Cardio": "figure.mixed.cardio"
        default: "figure.run"
        }
    }

    // Riscaldamento dei giorni di pesi (dalla vecchia app), con la spiegazione di ogni movimento
    static var riscaldamento: [(String, String)] {
        [
        (String(localized: "Cardio leggero (5 min)"), String(localized: "Tapis roulant a passo veloce o cyclette a ritmo facile: devi riuscire a parlare senza fatica.")),
        (String(localized: "Cerchi con le braccia (10 avanti, 10 indietro)"), String(localized: "Braccia tese ai lati, fai cerchi piccoli che diventano più ampi. Scalda spalle e scapole.")),
        (String(localized: "Oscillazioni delle gambe (10 per lato)"), String(localized: "In piedi, con una mano di appoggio, oscilla la gamba avanti e indietro, poi di lato. Scalda anche e femorali.")),
        (String(localized: "Squat a corpo libero (10 lenti)"), String(localized: "Piedi alla larghezza delle spalle, scendi lentamente e risali. Scalda ginocchia e caviglie.")),
        (String(localized: "Gatto-cammello (8 lenti)"), String(localized: "A quattro zampe: inarca la schiena verso il basso e poi verso l'alto, lentamente. Scalda la colonna.")),
        (String(localized: "Rotazione del busto (6 per lato)"), String(localized: "In piedi, braccia aperte, ruota il busto da una parte e dall'altra tenendo il bacino fermo.")),
    ]
    }
}
