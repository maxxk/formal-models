
class CellularAutomaton1D
{
	constructor()
	{
        this._CurrentState = [];
        this._NextState = [];
        this._NumberOfCells = 32;
        this._Rule = 0;
        this._StateChangedEventHandlers = [];
        this._NumberOfCellsChangedEventHandlers = [];
    }

    //---------------------------------------------------
    // PROPERTIES
    //---------------------------------------------------

	get StateChangedEventHandlers() { return this._StateChangedEventHandlers; }

	get NumberOfCellsChangedEventHandlers() { return this._NumberOfCellsChangedEventHandlers; }

	get CurrentState() { return this._CurrentState; }

	get NextState() { return this._NextState; }

	get Rule() { return this._Rule; }
	set Rule(Rule) { this._Rule = Rule; }

	get NumberOfCells() { return this._NumberOfCells; }
	set NumberOfCells(NumberOfCells)
    {
        this._NumberOfCells = NumberOfCells;
        this.FireNumberOfCellsChangedEvent();
    }

    //-------------------------------------------------------------------
    // METHODS
    //-------------------------------------------------------------------

    FireStateChangedEvent()
    {
        this._StateChangedEventHandlers.every(function (Handler) { Handler(); });
    }

    FireNumberOfCellsChangedEvent()
    {
        this._NumberOfCellsChangedEventHandlers.every(function (Handler) { Handler(); });
    }

    Randomize()
    {
        for (let i = 0; i < this._NumberOfCells; i++)
        {
            this._CurrentState[i] = parseInt(Math.random() * 2);
        }

        this.FireStateChangedEvent();
    }

    InitializeToCentre()
    {
        for (let i = 0; i < this._NumberOfCells; i++)
        {
            this._CurrentState[i] = 0;
        }

        this._CurrentState[Math.floor(this._NumberOfCells / 2)] = 1;

        this.FireStateChangedEvent();
    }

    CalculateNextState()
    {
        let PrevIndex;
        let NextIndex;
        let Neighbourhood;
        let RuleAsBinary = this._Rule.toString(2);

		// left pad binary to 8
        while (RuleAsBinary.length < 8)
            RuleAsBinary = "0" + RuleAsBinary;

        for (let i = 0; i < this._NumberOfCells; i++)
        {
            if (i == 0)
                PrevIndex = this._NumberOfCells - 1;
            else
                PrevIndex = i - 1;

            if (i == (this._NumberOfCells - 1))
                NextIndex = 0;
            else
                NextIndex = i + 1;

            Neighbourhood = this._CurrentState[PrevIndex].toString() + this._CurrentState[i].toString() + this._CurrentState[NextIndex].toString();

            switch (Neighbourhood)
            {
                case "111":
                    this._NextState[i] = RuleAsBinary[0];
                    break;
                case "110":
                    this._NextState[i] = RuleAsBinary[1];
                    break;
                case "101":
                    this._NextState[i] = RuleAsBinary[2];
                    break;
                case "100":
                    this._NextState[i] = RuleAsBinary[3];
                    break;
                case "011":
                    this._NextState[i] = RuleAsBinary[4];
                    break;
                case "010":
                    this._NextState[i] = RuleAsBinary[5];
                    break;
                case "001":
                    this._NextState[i] = RuleAsBinary[6];
                    break;
                case "000":
                    this._NextState[i] = RuleAsBinary[7];
                    break;
            }
        }

        for (let i = 0; i < this._NumberOfCells; i++)
        {
            this._CurrentState[i] = this._NextState[i];
        }

        this._NextState.length = 0;

        this.FireStateChangedEvent();
    }

    Iterate(Iterations)
    {
        for(let Iteration = 1; Iteration <= Iterations; Iteration++)
        {
            this.CalculateNextState();
        }
    }
}
