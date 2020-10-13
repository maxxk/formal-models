
class CellularAutomaton1DSVG
{
	constructor(SVGID, CA)
	{
        this._SVGID = SVGID;
        this._CA = CA;
        this._Iteration = 0;

        this._CellSize = 16;
        this._CellZeroColor = "#FFFFFF";
        this._CellOneColor = "#000000";

        let that = this;

        this._CA.StateChangedEventHandlers.push(function()
        {
            that._SetHeight(that._CellSize * that._Iteration);
            that._DrawState();
        });

        this._CA.NumberOfCellsChangedEventHandlers.push(function()
        {
            that._SetWidth(that._CellSize * that._CA.NumberOfCells);
        });

        this._SetHeight(this._CellSize * this._Iteration);
        this._SetWidth(this._CellSize * this._CA.NumberOfCells);
    }

    //---------------------------------------------------
    // PROPERTIES
    //---------------------------------------------------

	get CellSize() { return this._CellSize; }
	set CellSize(CellSize) { this._CellSize = CellSize; }

	get CellZeroColor() { return this._CellZeroColor; }
	set CellZeroColor(CellZeroColor) { this._CellZeroColor = CellZeroColor; }

	get CellOneColor() { return this._CellOneColor; }
	set CellOneColor(CellOneColor) { this._CellOneColor = CellOneColor; }

    //---------------------------------------------------
    // METHODS
    //---------------------------------------------------

    _DrawState()
    {
        for (let i = 0, m = this._CA.NumberOfCells; i < m; i++)
        {
            let rect = document.createElementNS("http://www.w3.org/2000/svg", 'rect');

            rect.setAttributeNS(null, 'x', i * this._CellSize);
            rect.setAttributeNS(null, 'y', this._Iteration * this._CellSize);
            rect.setAttributeNS(null, 'height', this._CellSize);
            rect.setAttributeNS(null, 'width', this._CellSize);

            if (this._CA.CurrentState[i] == 0)
            {
                rect.setAttributeNS(null, 'style', "fill:" + this._CellZeroColor + "; stroke:" + this._CellOneColor + "; stroke-width:" + 0.25 + ";");
            }
            else
            {
                rect.setAttributeNS(null, 'style', "fill:" + this._CellOneColor + "; stroke:" + this._CellZeroColor + "; stroke-width:" + 0.25 + ";");
            }

            document.getElementById(this._SVGID).appendChild(rect);
        }

        this._Iteration++;

        this._SetHeight(this._CellSize * this._Iteration);
    }

    _SetHeight(height)
    {
        document.getElementById(this._SVGID).setAttribute("height", height);
    }

    _SetWidth(width)
    {
        document.getElementById(this._SVGID).setAttribute("width", width);
    }

    Clear()
    {
        document.getElementById(this._SVGID).innerHTML = "";

        this._Iteration = 0;

        this._SetHeight(0);
    }
}
